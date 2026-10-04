//
//  CircuitGridTacticsTests.swift
//  CircuitGridTacticsTests
//
//  Created by Gopal Kumar on 27/09/26.
//

import Testing
@testable import CircuitGridTactics

struct CircuitGridTacticsTests {

    @Test func testTilePositionEquality() {
        let posA = TilePosition(row: 2, col: 2)
        let posB = TilePosition(row: 2, col: 2)
        let posC = TilePosition(row: 1, col: 2)
        
        #expect(posA == posB)
        #expect(posA != posC)
    }

    @Test func testTacticalUnitInitialization() {
        let position = TilePosition(row: 0, col: 0)
        let playerUnit = TacticalUnit(typeName: "Conductor", owner: .player, position: position)
        
        #expect(playerUnit.typeName == "Conductor")
        #expect(playerUnit.owner == .player)
        #expect(playerUnit.position == position)
    }
}
