//
//  GridModels.swift
//  CircuitGridTactics
//
//  Created by Gopal Kumar on 27/09/26.
//

import Foundation

/// Represents a discrete 2D matrix location on the grid board.
struct TilePosition: Equatable, Hashable {
    let row: Int
    let col: Int
}

/// Identifies controlling faction for tactical units.
enum UnitOwner {
    case player
    case ai
}

/// Dynamic game entity positioned on the board matrix.
class TacticalUnit: Identifiable {
    let id: UUID
    let typeName: String
    let owner: UnitOwner
    var position: TilePosition
    
    init(id: UUID = UUID(), typeName: String, owner: UnitOwner, position: TilePosition) {
        self.id = id
        self.typeName = typeName
        self.owner = owner
        self.position = position
    }
}
