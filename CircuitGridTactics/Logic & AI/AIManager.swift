import Foundation

// AI movement controller for tactical grid decisions
class AIManager {
    
    // Evaluates adjacent tiles and picks the move that gets the AI closest to the center power node
    func determineBestMove(
        for unit: TacticalUnit,
        allUnits: [TacticalUnit],
        obstacles: Set<TilePosition>
    ) -> TilePosition? {
        let center = TilePosition(row: 2, col: 2)
        let currentPos = unit.position
        
        // 4-directional movement candidates (Up, Down, Right, Left)
        let candidates = [
            TilePosition(row: currentPos.row + 1, col: currentPos.col),
            TilePosition(row: currentPos.row - 1, col: currentPos.col),
            TilePosition(row: currentPos.row, col: currentPos.col + 1),
            TilePosition(row: currentPos.row, col: currentPos.col - 1)
        ]
        
        var bestMove: TilePosition? = nil
        var shortestDistanceToCenter = Int.max
        
        for move in candidates {
            // Skip invalid tiles (out of bounds, blocked by obstacles, or occupied by units)
            guard move.row >= 0, move.row < 5, move.col >= 0, move.col < 5,
                  !obstacles.contains(move),
                  !allUnits.contains(where: { $0.position == move }) else { continue }
            
            // Calculate actual path distance to center bypassing obstacles
            let dist = shortestPathLength(from: move, to: center, obstacles: obstacles, allUnits: allUnits)
            if dist < shortestDistanceToCenter {
                shortestDistanceToCenter = dist
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    // BFS algorithm to find the shortest walkable path to the target tile
    private func shortestPathLength(
        from start: TilePosition,
        to target: TilePosition,
        obstacles: Set<TilePosition>,
        allUnits: [TacticalUnit]
    ) -> Int {
        var visited: Set<TilePosition> = [start]
        var queue: [(pos: TilePosition, dist: Int)] = [(start, 0)]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current.pos == target { return current.dist }
            
            let neighbors = [
                TilePosition(row: current.pos.row + 1, col: current.pos.col),
                TilePosition(row: current.pos.row - 1, col: current.pos.col),
                TilePosition(row: current.pos.row, col: current.pos.col + 1),
                TilePosition(row: current.pos.row, col: current.pos.col - 1)
            ]
            
            for neighbor in neighbors {
                let inside = neighbor.row >= 0 && neighbor.row < 5 && neighbor.col >= 0 && neighbor.col < 5
                let isBlockedUnit = allUnits.contains(where: { $0.position == neighbor && neighbor != target })
                
                // Add valid, unvisited tiles to queue
                if inside && !obstacles.contains(neighbor) && !isBlockedUnit && !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append((neighbor, current.dist + 1))
                }
            }
        }
        return Int.max // Target unreachable
    }
}
