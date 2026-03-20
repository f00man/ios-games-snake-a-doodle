import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query(sort: \HighScore.score, order: .reverse) private var scores: [HighScore]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if scores.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow.opacity(0.4))
                        Text("No scores yet.\nPlay a game!")
                            .multilineTextAlignment(.center)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                } else {
                    List {
                        ForEach(Array(scores.prefix(20).enumerated()), id: \.offset) { index, entry in
                            HStack(spacing: 12) {
                                Text(medalLabel(for: index))
                                    .font(.system(size: 20))
                                    .frame(width: 32)

                                Text("\(entry.score)")
                                    .font(.system(.title3, design: .monospaced, weight: .bold))
                                    .foregroundStyle(index == 0 ? .yellow : .green)

                                Spacer()

                                Text(entry.date, style: .date)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.gray)
                            }
                            .listRowBackground(Color(white: 0.08))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private func medalLabel(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)."
        }
    }
}
