import Foundation
import Combine
import SwiftUI

class GameEngine: ObservableObject {
    static let columns = 20
    static let rows    = 20  // square grid; remaining vertical space used for ads

    // Tick interval is CONSTANT — speed never changes, only length grows on eat
    static let tickInterval: TimeInterval = 0.2

    // Color food expires and respawns after this interval
    static let colorFoodLifetime: TimeInterval = 15.0

    // Palette of colors available for the color-change food / link coloring
    static let linkColorPalette: [Color] = [
        .green, .cyan, .orange, .pink, .purple,
        Color(red: 1.0, green: 0.85, blue: 0.0), // gold
        Color(red: 0.4, green: 1.0, blue: 0.4),  // lime
        Color(red: 1.0, green: 0.4, blue: 0.8),  // hot pink
        .mint, .teal, .white,
    ]

    @Published var snakeBody: [SnakeSegment] = []
    @Published var foods: [Food] = []
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var scoreMultiplier: Int = 1
    @Published var popupText: String? = nil

    private(set) var nextLinkColor: Color = .green
    private var direction: Direction = .right
    private var pendingDirection: Direction = .right
    private var timerCancellable: AnyCancellable?
    private var colorFoodExpiryCancellable: AnyCancellable?
    private var popupClearWork: DispatchWorkItem?

    func startGame() {
        let midCol = Self.columns / 2
        let midRow = Self.rows / 2
        nextLinkColor = .green
        snakeBody = [
            SnakeSegment(position: GridPosition(col: midCol + 1, row: midRow), color: .green),
            SnakeSegment(position: GridPosition(col: midCol,     row: midRow), color: .green),
            SnakeSegment(position: GridPosition(col: midCol - 1, row: midRow), color: .green),
        ]
        direction = .right
        pendingDirection = .right
        score = 0
        scoreMultiplier = 1
        popupText = nil
        isGameOver = false
        foods = []
        spawnFood(type: .grow)
        spawnFood(type: .colorChange)
        scheduleTimer()
    }

    func queueDirection(_ newDir: Direction) {
        guard newDir != direction.opposite else { return }
        pendingDirection = newDir
    }

    func stopGame() {
        timerCancellable?.cancel()
        timerCancellable = nil
        colorFoodExpiryCancellable?.cancel()
        colorFoodExpiryCancellable = nil
        popupClearWork?.cancel()
        popupClearWork = nil
    }

    // MARK: Private

    private func scheduleTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: Self.tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func scheduleColorFoodExpiry() {
        colorFoodExpiryCancellable?.cancel()
        colorFoodExpiryCancellable = Timer.publish(every: Self.colorFoodLifetime, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.colorFoodExpiryCancellable?.cancel()
                self?.colorFoodExpiryCancellable = nil
                self?.spawnFood(type: .colorChange)
            }
    }

    private func showPopup(_ text: String) {
        popupClearWork?.cancel()
        popupText = text
        let work = DispatchWorkItem { [weak self] in self?.popupText = nil }
        popupClearWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func tick() {
        guard !isGameOver else { return }
        direction = pendingDirection

        let head = snakeBody[0].position
        let raw: GridPosition
        switch direction {
        case .up:    raw = GridPosition(col: head.col,     row: head.row - 1)
        case .down:  raw = GridPosition(col: head.col,     row: head.row + 1)
        case .left:  raw = GridPosition(col: head.col - 1, row: head.row)
        case .right: raw = GridPosition(col: head.col + 1, row: head.row)
        }

        // Wrap around walls
        let wrapped = GridPosition(
            col: (raw.col + Self.columns) % Self.columns,
            row: (raw.row + Self.rows)    % Self.rows
        )

        // Self collision — exclude tail since it always vacates on a normal move
        if snakeBody.dropLast().contains(where: { $0.position == wrapped }) {
            triggerGameOver()
            return
        }

        if let foodIdx = foods.firstIndex(where: { $0.position == wrapped }) {
            let eaten = foods[foodIdx]
            switch eaten.type {

            case .grow:
                // Insert a new head segment in nextLinkColor.
                // Old segments keep their positions and colors — the chain just gets one longer.
                snakeBody.insert(SnakeSegment(position: wrapped, color: nextLinkColor), at: 0)
                let points = scoreMultiplier
                score += points
                let popupMsg = scoreMultiplier > 1
                    ? "x\(scoreMultiplier) → +\(points) pts!"
                    : "+1"
                scoreMultiplier = 1
                showPopup(popupMsg)
                spawnFood(type: .grow)

            case .colorChange:
                // Stack the multiplier, change color of future grow-segments, move normally.
                scoreMultiplier += 1
                nextLinkColor = eaten.displayColor
                showPopup("⚡ x\(scoreMultiplier) MULT")
                spawnFood(type: .colorChange)
                rotatePositions(to: wrapped)
            }
        } else {
            // Normal movement — rotate positions; colors stay fixed to their chain index.
            rotatePositions(to: wrapped)
        }
    }

    /// Shifts every segment's position backward one step and places the head at `pos`.
    /// Colors are NOT touched — they remain bound to their index in the chain.
    private func rotatePositions(to pos: GridPosition) {
        for i in stride(from: snakeBody.count - 1, through: 1, by: -1) {
            snakeBody[i].position = snakeBody[i - 1].position
        }
        snakeBody[0].position = pos
    }

    private func spawnFood(type: FoodType) {
        let color: Color
        switch type {
        case .grow:
            color = .red
        case .colorChange:
            let options = Self.linkColorPalette.filter { $0 != nextLinkColor }
            color = options.randomElement() ?? .cyan
        }

        let occupied = Set(snakeBody.map { $0.position })
            .union(foods.filter { $0.type != type }.map { $0.position })

        var candidate: GridPosition
        repeat {
            candidate = GridPosition(
                col: Int.random(in: 0..<Self.columns),
                row: Int.random(in: 0..<Self.rows)
            )
        } while occupied.contains(candidate)

        let newFood = Food(position: candidate, type: type, displayColor: color)
        if let idx = foods.firstIndex(where: { $0.type == type }) {
            foods[idx] = newFood
        } else {
            foods.append(newFood)
        }

        // Reset the 15s expiry clock every time a color food is placed (eaten or expired)
        if type == .colorChange {
            scheduleColorFoodExpiry()
        }
    }

    private func triggerGameOver() {
        timerCancellable?.cancel()
        timerCancellable = nil
        colorFoodExpiryCancellable?.cancel()
        colorFoodExpiryCancellable = nil
        popupClearWork?.cancel()
        popupClearWork = nil
        isGameOver = true
    }
}
