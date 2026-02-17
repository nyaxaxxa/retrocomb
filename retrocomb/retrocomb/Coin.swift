//
//  Coin.swift
//  retrocomb
//
//  Space Flappy Game - Coin/Star collectible
//

import SpriteKit

class Coin: SKShapeNode {
    var isCollected = false
    private var rotationAngle: CGFloat = 0
    
    init(position: CGPoint, theme: ColorTheme) {
        super.init()
        
        self.position = position
        self.name = "coin"
        
        // Create star shape
        let starPath = Coin.createStarPath(points: 5, outerRadius: GameConfig.Coin.size, innerRadius: GameConfig.Coin.size * 0.5)
        self.path = starPath
        self.fillColor = theme.skSecondary
        self.strokeColor = theme.skPrimary
        self.lineWidth = 2
        self.glowWidth = 3
        
        // Physics
        self.physicsBody = SKPhysicsBody(circleOfRadius: GameConfig.Coin.size * 0.7)
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.coin
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.player
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
        
        // Add rotation animation
        let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 2.0)
        let repeatAction = SKAction.repeatForever(rotateAction)
        self.run(repeatAction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Create star path
    static func createStarPath(points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angle = CGFloat.pi / CGFloat(points)
        
        let startPoint = CGPoint(x: outerRadius * cos(-CGFloat.pi / 2), y: outerRadius * sin(-CGFloat.pi / 2))
        path.move(to: startPoint)
        
        for i in 1...(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = radius * cos(angle * CGFloat(i) - CGFloat.pi / 2)
            let y = radius * sin(angle * CGFloat(i) - CGFloat.pi / 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
    
    func collect() {
        isCollected = true
        
        // Animation
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([scaleUp, fadeOut, remove])
        self.run(sequence)
    }
    
    func updateTheme(_ theme: ColorTheme) {
        self.fillColor = theme.skSecondary
        self.strokeColor = theme.skPrimary
    }
}
