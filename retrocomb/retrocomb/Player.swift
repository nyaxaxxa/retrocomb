//
//  Player.swift
//  retrocomb
//
//  Space Flappy Game - Player Ship
//

import SpriteKit

class Player: SKShapeNode {
    var velocity: CGVector = CGVector.zero
    var isAlive = true
    var hasShield = false
    var shieldNode: SKShapeNode?
    
    // Upgrades
    var speedMultiplier: CGFloat = 1.0
    var sizeMultiplier: CGFloat = 1.0
    var magnetMultiplier: CGFloat = 1.0
    var magnetRange: CGFloat {
        return GameConfig.Coin.magnetRange * magnetMultiplier
    }
    
    // Current level and theme
    var currentLevel: Int = 1
    private var currentTheme: ColorTheme = ColorTheme.classicGreen
    
    // Particles
    var particles: [Particle] = []
    
    init(level: Int, theme: ColorTheme) {
        super.init()
        
        self.currentLevel = level
        self.currentTheme = theme
        self.name = "player"
        
        setupForLevel(level: level, theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    func setupForLevel(level: Int, theme: ColorTheme) {
        self.currentLevel = level
        self.currentTheme = theme
        
        // Remove old path
        self.path = nil
        
        switch level {
        case 1:
            setupLevel1Ship(theme: theme)
        case 2:
            setupLevel2Ship(theme: theme)
        case 3:
            setupLevel3Ship(theme: theme)
        default:
            setupLevel1Ship(theme: theme)
        }
        
        // Setup shield if active
        if hasShield {
            addShield(theme: theme)
        }
    }
    
    // Level 1 - Horizontal rectangle ship
    private func setupLevel1Ship(theme: ColorTheme) {
        let size = CGSize(
            width: GameConfig.Level1.playerSize.width * sizeMultiplier,
            height: GameConfig.Level1.playerSize.height * sizeMultiplier
        )
        
        // Create rectangle ship
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: -size.width/2, y: -size.height/2))
        shipPath.addLine(to: CGPoint(x: size.width/2, y: 0))
        shipPath.addLine(to: CGPoint(x: -size.width/2, y: size.height/2))
        shipPath.closeSubpath()
        
        self.path = shipPath
        self.fillColor = theme.skPrimary
        self.strokeColor = theme.skPrimary
        self.lineWidth = 2
        self.glowWidth = 4
        
        // Physics
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 0.8, height: size.height * 0.8))
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.pipe | GameConfig.PhysicsCategory.coin
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = true
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.affectedByGravity = false
    }
    
    // Level 2 - Vertical ship
    private func setupLevel2Ship(theme: ColorTheme) {
        let size = CGSize(
            width: GameConfig.Level2.playerSize.width * sizeMultiplier,
            height: GameConfig.Level2.playerSize.height * sizeMultiplier
        )
        
        // Create vertical ship
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: 0, y: size.height/2))
        shipPath.addLine(to: CGPoint(x: -size.width/2, y: -size.height/2))
        shipPath.addLine(to: CGPoint(x: size.width/2, y: -size.height/2))
        shipPath.closeSubpath()
        
        self.path = shipPath
        self.fillColor = theme.skPrimary
        self.strokeColor = theme.skPrimary
        self.lineWidth = 2
        self.glowWidth = 4
        
        // Physics
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 0.8, height: size.height * 0.8))
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.asteroid | GameConfig.PhysicsCategory.coin
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = false
    }
    
    // Level 3 - Triangle ship that rotates
    private func setupLevel3Ship(theme: ColorTheme) {
        let size = GameConfig.Level3.playerSize.width * sizeMultiplier
        
        // Create triangle ship
        let shipPath = CGMutablePath()
        shipPath.move(to: CGPoint(x: size, y: 0))
        shipPath.addLine(to: CGPoint(x: -size/2, y: size/2))
        shipPath.addLine(to: CGPoint(x: -size/2, y: -size/2))
        shipPath.closeSubpath()
        
        self.path = shipPath
        self.fillColor = theme.skPrimary
        self.strokeColor = theme.skPrimary
        self.lineWidth = 2
        self.glowWidth = 4
        
        // Physics
        self.physicsBody = SKPhysicsBody(circleOfRadius: size * 0.8)
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.enemy | GameConfig.PhysicsCategory.food | GameConfig.PhysicsCategory.coin
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = true
    }
    
    // Flap (Level 1) - как в Flappy Bird
    func flap() {
        if currentLevel == 1 {
            // Сбрасываем скорость и даём импульс вверх
            velocity.dy = GameConfig.Level1.flapStrength
            
            // Небольшая анимация
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            self.run(SKAction.sequence([scaleUp, scaleDown]))
        }
    }
    
    // Apply gravity (Level 1)
    func applyGravity(multiplier: CGFloat = 1.0) {
        velocity.dy += GameConfig.Level1.gravity * multiplier
    }
    
    // Update position
    func updatePosition() {
        position.x += velocity.dx
        position.y += velocity.dy
    }
    
    // Add shield
    func addShield(theme: ColorTheme) {
        hasShield = true
        
        // Remove old shield
        shieldNode?.removeFromParent()
        
        // Create shield circle
        let radius: CGFloat = 40 * sizeMultiplier
        let shield = SKShapeNode(circleOfRadius: radius)
        shield.strokeColor = theme.skSecondary
        shield.fillColor = theme.skSecondary.withAlphaComponent(0.2)
        shield.lineWidth = 3
        shield.glowWidth = 5
        shield.name = "shield"
        
        // Add pulse animation
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        shield.run(SKAction.repeatForever(pulse))
        
        self.addChild(shield)
        shieldNode = shield
    }
    
    // Remove shield
    func removeShield() {
        hasShield = false
        
        // Animation
        if let shield = shieldNode {
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            shield.run(SKAction.sequence([fadeOut, remove]))
        }
        shieldNode = nil
    }
    
    // Create engine particles
    func createEngineParticles() -> [Particle] {
        var particlePosition = position
        var particleDirection = CGVector.zero
        
        switch currentLevel {
        case 1:
            // Particles from the left side
            particlePosition = CGPoint(x: position.x - 25, y: position.y)
            particleDirection = CGVector(dx: -1, dy: 0)
            
        case 2:
            // Particles from the bottom
            particlePosition = CGPoint(x: position.x, y: position.y - 25)
            particleDirection = CGVector(dx: 0, dy: -1)
            
        case 3:
            // Particles opposite to velocity direction
            if velocity.dx != 0 || velocity.dy != 0 {
                let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
                if speed > 0.5 {
                    let normalizedDx = -velocity.dx / speed
                    let normalizedDy = -velocity.dy / speed
                    particleDirection = CGVector(dx: normalizedDx, dy: normalizedDy)
                    particlePosition = CGPoint(
                        x: position.x + normalizedDx * 15,
                        y: position.y + normalizedDy * 15
                    )
                }
            }
            
        default:
            break
        }
        
        return ParticleEmitter.createEngineParticles(
            at: particlePosition,
            direction: particleDirection,
            color: currentTheme.skSecondary
        )
    }
    
    // Update rotation for level 3
    func updateRotation() {
        if currentLevel == 3 {
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            if speed > 0.5 {
                let angle = atan2(velocity.dy, velocity.dx)
                self.zRotation = angle
            }
        }
    }
    
    // Grow (Level 3)
    func grow(amount: CGFloat) {
        sizeMultiplier += amount
        setupForLevel(level: currentLevel, theme: currentTheme)
    }
    
    // Die animation
    func die() {
        isAlive = false
        
        // Create explosion
        let explosion = ParticleEmitter.createExplosion(at: position, color: currentTheme.skPrimary)
        if let parent = self.parent {
            for particle in explosion {
                parent.addChild(particle)
            }
        }
        
        // Fade out
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        self.run(SKAction.sequence([fadeOut, remove]))
    }
    
    // Update theme
    func updateTheme(_ theme: ColorTheme) {
        self.currentTheme = theme
        setupForLevel(level: currentLevel, theme: theme)
    }
}
