import Foundation
import SwiftData

@Model
final class HighScore {
    var score: Int
    var date: Date

    init(score: Int, date: Date = .now) {
        self.score = score
        self.date = date
    }
}
