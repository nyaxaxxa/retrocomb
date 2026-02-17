//
//  Food.swift
//  retrocomb
//
//  Space Flappy Game - Food for Level 3
//

import SpriteKit

class Food: SKShapeNode {
    var isEaten = false
    private var pulseAction: SKAction?
    
    init(position: CGPoint, theme: ColorTheme) {
        super.init()
        
        self.position = position
        self.name = "food"
        
        // Create small circle
        let radius: CGFloat = 6
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor = theme.skSecondary
        circle.strokeColor = theme.skSecondary
        circle.glowWidth = 2
        self.path = circle.path
        self.fillColor = theme.skSecondary
        self.strokeColor = .clear
        
        // Physics
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.food
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.player
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
        
        // Pulse animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        pulseAction = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        if let pulseAction {
            self.run(pulseAction)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    func eat() {
        isEaten = true
        
        // Remove pulse
        if pulseAction != nil {
            self.removeAllActions()
        }
        
        // Animation
        let scaleUp = SKAction.scale(to: 2.0, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.removeFromParent()
        let group = SKAction.group([scaleUp, fadeOut])
        self.run(SKAction.sequence([group, remove]))
    }
    
    func updateTheme(_ theme: ColorTheme) {
        self.fillColor = theme.skSecondary
        self.strokeColor = theme.skSecondary
    }
}
