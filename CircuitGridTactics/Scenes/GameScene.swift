//
//  GameScene.swift
//  CircuitGridTactics
//
//  Created by Gopal Kumar on 27/09/26.
//

import SpriteKit
import Combine

class GameScene: SKScene, ObservableObject {
    
    let aiManager = AIManager()
    
    // Grid settings
    let boardSize = 5
    var tileSize: CGFloat = 60.0
    let tileSpacing: CGFloat = 6.0
    var gridOrigin: CGPoint = .zero
    
    var units: [TacticalUnit] = []
    var selectedUnit: TacticalUnit?
    
    // Published properties for SwiftUI HUD state sync
    @Published var playerAP: Int = 2
    @Published var isPlayerTurn: Bool = true
    @Published var gameOverMessage: String? = nil
    
    // Track grid elements
    private var obstaclePositions: Set<TilePosition> = []
    private var tileNodes: [TilePosition: SKShapeNode] = [:]
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)
        view.ignoresSiblingOrder = true
    }
    
    // Handle dynamic screen resizing & calculate tile layout
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0 && size.height > 0 else { return }
        
        let margin: CGFloat = 32.0
        let availableWidth = size.width - (margin * 2)
        tileSize = floor(availableWidth / CGFloat(boardSize))
        
        calculateGridOrigin()
        resetGame()
    }
    
    // Reset state and re-generate grid layout
    func resetGame() {
        removeAllChildren()
        units.removeAll()
        tileNodes.removeAll()
        obstaclePositions.removeAll()
        selectedUnit = nil
        playerAP = 2
        isPlayerTurn = true
        gameOverMessage = nil
        
        guard size.width > 0 && size.height > 0 else { return }
        
        calculateGridOrigin()
        
        // Loop generation until both units have a valid BFS path to center tile
        repeat {
            setupObstacles()
            spawnInitialUnits()
        } while !hasPathToCenter(from: units[0].position) || !hasPathToCenter(from: units[1].position)
        
        // Draw grid tiles
        setupGrid()
        
        // Render unit nodes over tiles
        for unit in units {
            renderUnitNode(unit)
        }
    }
    
    // Randomly generate map obstacles while keeping center area accessible
    private func setupObstacles() {
        obstaclePositions.removeAll()
        
        let center = TilePosition(row: 2, col: 2)
        var possibleObstacleTiles: [TilePosition] = []
        
        for r in 0..<boardSize {
            for c in 0..<boardSize {
                let pos = TilePosition(row: r, col: c)
                if pos != center {
                    possibleObstacleTiles.append(pos)
                }
            }
        }
        
        possibleObstacleTiles.shuffle()
        
        // Limit total obstacles to prevent map blockages
        let obstacleCount = Int.random(in: 2...3)
        
        for pos in possibleObstacleTiles.prefix(obstacleCount) {
            obstaclePositions.insert(pos)
        }
    }
    
    // Center grid on screen
    func calculateGridOrigin() {
        let totalWidth = CGFloat(boardSize) * tileSize
        let totalHeight = CGFloat(boardSize) * tileSize
        
        gridOrigin = CGPoint(
            x: (size.width - totalWidth) / 2.0 + (tileSize / 2.0),
            y: (size.height - totalHeight) / 2.0 + (tileSize / 2.0)
        )
    }
    
    // Convert matrix indices to screen point
    func pointFor(row: Int, column: Int) -> CGPoint {
        return CGPoint(
            x: gridOrigin.x + CGFloat(column) * tileSize,
            y: gridOrigin.y + CGFloat(row) * tileSize
        )
    }
    
    // Build grid visual nodes
    private func setupGrid() {
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let pos = TilePosition(row: row, col: col)
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize), cornerRadius: 8)
                tile.position = pointFor(row: row, column: col)
                
                // Style center objective tile differently
                if row == 2 && col == 2 {
                    tile.fillColor = SKColor.systemYellow.withAlphaComponent(0.25)
                    tile.strokeColor = .systemYellow
                    tile.lineWidth = 2.0
                } else if obstaclePositions.contains(pos) {
                    tile.fillColor = SKColor.purple.withAlphaComponent(0.5)
                    tile.strokeColor = .magenta
                    tile.lineWidth = 1.5
                } else {
                    tile.fillColor = SKColor.darkGray.withAlphaComponent(0.4)
                    tile.strokeColor = SKColor.cyan.withAlphaComponent(0.3)
                    tile.lineWidth = 1.0
                }
                
                tile.name = "tile_\(row)_\(col)"
                tileNodes[pos] = tile
                addChild(tile)
            }
        }
    }
    
    // Create/update unit circle sprites
    private func renderUnitNode(_ unit: TacticalUnit) {
        let unitNodeName = "unit_\(unit.owner)"
        childNode(withName: unitNodeName)?.removeFromParent()
        
        let radius = tileSize * 0.35
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.name = unitNodeName
        circle.position = pointFor(row: unit.position.row, column: unit.position.col)
        circle.zPosition = 10
        
        if unit.owner == .player {
            circle.fillColor = .cyan
            circle.strokeColor = .white
        } else {
            circle.fillColor = .systemRed
            circle.strokeColor = .white
        }
        circle.lineWidth = 2.0
        addChild(circle)
    }
    
    // Spawn player and AI on open outer perimeter tiles
    private func spawnInitialUnits() {
        let center = TilePosition(row: 2, col: 2)
        
        var validSpawnTiles: [TilePosition] = []
        for r in 0..<boardSize {
            for c in 0..<boardSize {
                let pos = TilePosition(row: r, col: c)
                let isPerimeter = (r == 0 || r == 4 || c == 0 || c == 4)
                if isPerimeter && !obstaclePositions.contains(pos) && pos != center {
                    validSpawnTiles.append(pos)
                }
            }
        }
        
        validSpawnTiles.shuffle()
        
        let playerSpawn = validSpawnTiles.popLast() ?? TilePosition(row: 0, col: 0)
        let aiSpawn = validSpawnTiles.popLast() ?? TilePosition(row: 4, col: 4)
        
        obstaclePositions.remove(playerSpawn)
        obstaclePositions.remove(aiSpawn)
        
        units.removeAll()
        
        let playerUnit = TacticalUnit(
            typeName: "Conductor",
            owner: .player,
            position: playerSpawn
        )
        units.append(playerUnit)
        
        let aiUnit = TacticalUnit(
            typeName: "Sentry",
            owner: .ai,
            position: aiSpawn
        )
        units.append(aiUnit)
    }
    
    func isTileOccupied(_ position: TilePosition) -> Bool {
        let isUnitOccupied = units.contains(where: { $0.position == position })
        let isObstacle = obstaclePositions.contains(position)
        return isUnitOccupied || isObstacle
    }
    
    func isAdjacent(from: TilePosition, to: TilePosition) -> Bool {
        let rowDiff = abs(from.row - to.row)
        let colDiff = abs(from.col - to.col)
        return rowDiff + colDiff == 1
    }
    
    func moveUnit(_ unit: TacticalUnit, to newPosition: TilePosition) {
        if let index = units.firstIndex(where: { $0.id == unit.id }) {
            units[index].position = newPosition
            renderUnitNode(units[index])
        }
    }
    
    func endPlayerTurn() {
        guard isPlayerTurn, gameOverMessage == nil else { return }
        
        clearHighlights()
        isPlayerTurn = false
        selectedUnit = nil
        
        // Small delay before AI actions start
        run(SKAction.wait(forDuration: 0.6)) { [weak self] in
            self?.executeAITurn()
        }
    }
    
    // Execute AI turn using 2 action points
    private func executeAITurn() {
        guard let aiUnit = units.first(where: { $0.owner == .ai }) else { return }
        var movesRemaining = 2
        
        func performNextAIMove() {
            if movesRemaining > 0 {
                if let bestMove = aiManager.determineBestMove(for: aiUnit, allUnits: units, obstacles: obstaclePositions) {
                    moveUnit(aiUnit, to: bestMove)
                    movesRemaining -= 1
                    
                    if checkGameConditions() { return }
                    
                    run(SKAction.wait(forDuration: 0.4)) {
                        performNextAIMove()
                    }
                } else {
                    finishAITurn()
                }
            } else {
                finishAITurn()
            }
        }
        performNextAIMove()
    }
    
    private func finishAITurn() {
        guard gameOverMessage == nil else { return }
        startPlayerTurn()
    }
    
    func startPlayerTurn() {
        playerAP = 2
        isPlayerTurn = true
        _ = checkGameConditions()
    }
    
    // Touch handling for unit selection and movement
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isPlayerTurn, playerAP > 0, gameOverMessage == nil else { return }
        let location = touch.location(in: self)
        
        let col = Int(round((location.x - gridOrigin.x) / tileSize))
        let row = Int(round((location.y - gridOrigin.y) / tileSize))
        
        guard row >= 0, row < boardSize, col >= 0, col < boardSize else { return }
        let tappedPosition = TilePosition(row: row, col: col)
        
        if let playerUnit = units.first(where: { $0.position == tappedPosition && $0.owner == .player }) {
            selectedUnit = playerUnit
            highlightValidMoves(for: playerUnit)
        } else if let unit = selectedUnit {
            if isAdjacent(from: unit.position, to: tappedPosition) && !isTileOccupied(tappedPosition) {
                clearHighlights()
                moveUnit(unit, to: tappedPosition)
                selectedUnit = nil
                
                playerAP -= 1
                
                if checkGameConditions() { return }
                
                if playerAP == 0 {
                    endPlayerTurn()
                }
            }
        }
    }
    
    // Highlight adjacent un-occupied tiles in green
    private func highlightValidMoves(for unit: TacticalUnit) {
        clearHighlights()
        let candidates = [
            TilePosition(row: unit.position.row + 1, col: unit.position.col),
            TilePosition(row: unit.position.row - 1, col: unit.position.col),
            TilePosition(row: unit.position.row, col: unit.position.col + 1),
            TilePosition(row: unit.position.row, col: unit.position.col - 1)
        ]
        
        for pos in candidates {
            if pos.row >= 0 && pos.row < boardSize && pos.col >= 0 && pos.col < boardSize && !isTileOccupied(pos) {
                if let tile = tileNodes[pos] {
                    tile.strokeColor = .green
                    tile.lineWidth = 2.5
                }
            }
        }
    }
    
    // Restore default tile strokes
    private func clearHighlights() {
        for (pos, tile) in tileNodes {
            if pos.row == 2 && pos.col == 2 {
                tile.strokeColor = .systemYellow
                tile.lineWidth = 2.0
            } else if obstaclePositions.contains(pos) {
                tile.strokeColor = .magenta
                tile.lineWidth = 1.5
            } else {
                tile.strokeColor = SKColor.cyan.withAlphaComponent(0.3)
                tile.lineWidth = 1.0
            }
        }
    }
    
    // Check if any unit occupies center tile (2, 2)
    @discardableResult
    private func checkGameConditions() -> Bool {
        let powerNodePos = TilePosition(row: 2, col: 2)
        
        if let occupyingUnit = units.first(where: { $0.position == powerNodePos }) {
            if occupyingUnit.owner == .player {
                gameOverMessage = "VICTORY!\nPOWER NODE HELD"
                return true
            } else if occupyingUnit.owner == .ai {
                gameOverMessage = "DEFEAT!\nAI HELD NODE"
                return true
            }
        }
        return false
    }
    
    // BFS traversal to check if power node is reachable from start tile
    private func hasPathToCenter(from start: TilePosition) -> Bool {
        let target = TilePosition(row: 2, col: 2)
        var visited: Set<TilePosition> = [start]
        var queue: [TilePosition] = [start]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == target { return true }
            
            let neighbors = [
                TilePosition(row: current.row + 1, col: current.col),
                TilePosition(row: current.row - 1, col: current.col),
                TilePosition(row: current.row, col: current.col + 1),
                TilePosition(row: current.row, col: current.col - 1)
            ]
            
            for neighbor in neighbors {
                let inside = neighbor.row >= 0 && neighbor.row < boardSize && neighbor.col >= 0 && neighbor.col < boardSize
                if inside && !obstaclePositions.contains(neighbor) && !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }
        return false
    }
}
