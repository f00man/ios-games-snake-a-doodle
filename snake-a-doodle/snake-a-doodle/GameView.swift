import SwiftUI

struct GameView: View {
    @ObservedObject var engine: GameEngine
    @Environment(\.dismiss) var dismiss

    private let cellPad: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            // Board is square: cell size driven by width only
            let cellSize = geo.size.width / CGFloat(GameEngine.columns)
            let boardSide = geo.size.width  // boardW == boardH (square)

            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Score bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .font(.title2)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            if engine.scoreMultiplier > 1 {
                                Text("⚡ x\(engine.scoreMultiplier)")
                                    .font(.system(.subheadline, design: .monospaced).bold())
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.yellow)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            Text("Score: \(engine.score)")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "xmark").opacity(0)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 54)

                    // Square game board with popup overlay
                    ZStack {
                        Canvas { ctx, _ in
                            drawBoard(ctx: ctx, cellSize: cellSize, side: boardSide)
                        }
                        .frame(width: boardSide, height: boardSide)
                        .border(Color.green.opacity(0.35), width: 1)
                        .contentShape(Rectangle())
                        .gesture(swipeGesture)

                        // Score / multiplier popup
                        if let popup = engine.popupText {
                            Text(popup)
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.6).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .id(popup)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: engine.popupText)

                    Spacer()

                    // Ad banner — visible for non-paying users (replaced by real AdMob banner)
                    AdBannerView()
                }
            }
        }
    }

    // MARK: Drawing

    private func drawBoard(ctx: GraphicsContext, cellSize: CGFloat, side: CGFloat) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: side, height: side)), with: .color(.black))

        // Faint grid
        for col in 0..<GameEngine.columns {
            for row in 0..<GameEngine.rows {
                ctx.fill(Path(cell(col: col, row: row, cellSize: cellSize, inset: cellPad)),
                         with: .color(.gray.opacity(0.07)))
            }
        }

        // Snake — each segment uses its stored color
        for (i, seg) in engine.snakeBody.enumerated() {
            let rect = cell(col: seg.position.col, row: seg.position.row, cellSize: cellSize, inset: cellPad)
            let isHead = i == 0
            let radius = isHead ? cellSize * 0.35 : cellSize * 0.18
            let color = isHead ? seg.color : seg.color.opacity(0.75)
            ctx.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
        }

        // Foods
        for food in engine.foods {
            switch food.type {
            case .grow:
                let r = cell(col: food.position.col, row: food.position.row, cellSize: cellSize, inset: cellPad * 2.5)
                ctx.fill(Path(ellipseIn: r), with: .color(.red))

            case .colorChange:
                let outer = cell(col: food.position.col, row: food.position.row, cellSize: cellSize, inset: cellPad)
                let inner = cell(col: food.position.col, row: food.position.row, cellSize: cellSize, inset: cellPad * 2.5)
                ctx.fill(Path(ellipseIn: inner), with: .color(food.displayColor))
                ctx.stroke(Path(ellipseIn: outer), with: .color(.white.opacity(0.7)), lineWidth: 1.5)
            }
        }
    }

    private func cell(col: Int, row: Int, cellSize: CGFloat, inset: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(col) * cellSize + inset,
            y: CGFloat(row) * cellSize + inset,
            width: cellSize - inset * 2,
            height: cellSize - inset * 2
        )
    }

    // MARK: Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onEnded { val in
                let dx = val.translation.width
                let dy = val.translation.height
                if abs(dx) > abs(dy) {
                    engine.queueDirection(dx > 0 ? .right : .left)
                } else {
                    engine.queueDirection(dy > 0 ? .down : .up)
                }
            }
    }
}
