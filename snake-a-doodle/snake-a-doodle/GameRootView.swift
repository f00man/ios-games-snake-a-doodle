import SwiftUI
import SwiftData

/// Hosts the active game, game-over prompt, and post-game canvas.
struct GameRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = GameEngine()
    @State private var showGameOver = false
    @State private var showPostGame = false

    var body: some View {
        ZStack {
            if showPostGame {
                PostGameCanvasView(
                    snakeBody: engine.snakeBody,
                    foods: engine.foods,
                    score: engine.score,
                    onQuit: { dismiss() },
                    onRestart: {
                        showPostGame = false
                        engine.startGame()
                    }
                )
            } else {
                GameView(engine: engine)
                    .onAppear { engine.startGame() }
                    .onChange(of: engine.isGameOver) { _, isOver in
                        guard isOver else { return }
                        saveScore(engine.score)
                        showGameOver = true
                    }

                if showGameOver {
                    GameOverOverlay(
                        score: engine.score,
                        onDraw: {
                            showGameOver = false
                            showPostGame = true
                        },
                        onRestart: {
                            showGameOver = false
                            engine.startGame()
                        }
                    )
                }
            }
        }
        .onDisappear { engine.stopGame() }
    }

    private func saveScore(_ score: Int) {
        guard score > 0 else { return }
        modelContext.insert(HighScore(score: score))
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlay: View {
    let score: Int
    let onDraw: () -> Void
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("GAME OVER")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundStyle(.red)
                    Text("Score: \(score)")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 14) {
                    Button(action: onDraw) {
                        Label("Draw on it", systemImage: "pencil.and.scribble")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button(action: onRestart) {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(32)
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
        }
    }
}
