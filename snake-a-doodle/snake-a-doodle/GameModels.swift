import Foundation
import SwiftUI

enum Direction: Equatable {
    case up, down, left, right

    var opposite: Direction {
        switch self {
        case .up:    return .down
        case .down:  return .up
        case .left:  return .right
        case .right: return .left
        }
    }
}

struct GridPosition: Equatable, Hashable {
    var col: Int
    var row: Int
}

/// One segment of the snake body, carrying its own color.
struct SnakeSegment {
    var position: GridPosition
    var color: Color
}

enum FoodType {
    /// Eating this elongates the snake and adds to score.
    case grow
    /// Eating this changes the color of future-added segments (no growth).
    case colorChange
}

struct Food {
    var position: GridPosition
    var type: FoodType
    /// Visual color. For .colorChange, this is also the new link color that will be applied.
    var displayColor: Color
}
