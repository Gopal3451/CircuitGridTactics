//
//  ContentView.swift
//  CircuitGridTactics
//
//  Created by Gopal Kumar on 27/09/26.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    // Shared GameScene instance observed by SwiftUI to update HUD state
    @StateObject private var gameScene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()
    
    var body: some View {
        ZStack {
            // Dark background behind grid
            Color(red: 0.08, green: 0.09, blue: 0.12)
                .ignoresSafeArea()
            
            // SpriteKit game board
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            
            // Main HUD overlay
            VStack {
                // Header bar showing current turn status and available action points
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CIRCUIT GRID TACTICS")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        Text(gameScene.isPlayerTurn ? "PLAYER TURN" : "AI THINKING...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(gameScene.isPlayerTurn ? .green : .red)
                    }
                    
                    Spacer()
                    
                    // Action Points (AP) indicator dots
                    HStack(spacing: 6) {
                        Text("AP")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        ForEach(0..<2, id: \.self) { index in
                            Circle()
                                .fill(index < gameScene.playerAP ? Color.cyan : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                }
                .padding()
                
                Spacer()
                
                // Bottom control panel for manual turn completion
                HStack {
                    Spacer()
                    Button(action: {
                        gameScene.endPlayerTurn()
                    }) {
                        Text("END TURN")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(gameScene.isPlayerTurn ? Color.blue : Color.gray.opacity(0.4))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cyan, lineWidth: 1)
                            )
                    }
                    .disabled(!gameScene.isPlayerTurn)
                }
                .padding()
            }
            
            // Pop-up dialog displayed when a win/loss condition triggers
            if let message = gameScene.gameOverMessage {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(message)
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundColor(message.contains("VICTORY") ? .cyan : .red)
                    
                    Button(action: {
                        gameScene.resetGame()
                    }) {
                        Text("PLAY AGAIN")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.cyan)
                            .cornerRadius(8)
                    }
                }
                .padding(32)
                .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
