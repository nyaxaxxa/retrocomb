//
//  Enemy.swift
//  retrocomb
//
//  Space Flappy Game - Enemy for Level 3
//

import SpriteKit

class Enemy: SKShapeNode {
    var velocity: CGVector = CGVector.zero
    var size: CGFloat = 20
    var moveSpeed: CGFloat = 1.5
    var isAlive = true
    
    init(position: CGPoint, size: CGFloat, theme: ColorTheme) {
        super.init()
        
        self.position = position
        self.size = size
        // Враги теперь БЫСТРЕЕ и опаснее!
        self.moveSpeed = GameConfig.Level3.enemyBaseSpeed + (size / 50)
        self.name = "enemy"
        
        // Create triangle enemy
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size, y: 0))
        path.addLine(to: CGPoint(x: -size/2, y: size/2))
        path.addLine(to: CGPoint(x: -size/2, y: -size/2))
        path.closeSubpath()
        
        self.path = path
        self.fillColor = theme.skPrimary.withAlphaComponent(0.8)
        self.strokeColor = theme.skPrimary
        self.lineWidth = 2
        self.glowWidth = 3
        
        // Physics
        self.physicsBody = SKPhysicsBody(circleOfRadius: size * 0.8)
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.player | GameConfig.PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
        
        // Random initial velocity
        let angle = CGFloat.random(in: 0...(2 * .pi))
        velocity = CGVector(dx: cos(angle) * moveSpeed, dy: sin(angle) * moveSpeed)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    func updateAI(playerPosition: CGPoint, worldBounds: CGSize) {
        // Calculate distance to player
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // АГРЕССИВНЫЙ AI - все враги преследуют в пределах дальности
        let aggressionRange = GameConfig.Level3.enemyAggressionRange
        
        if distance < aggressionRange {
            // В ПРЕДЕЛАХ ВИДИМОСТИ - АКТИВНОЕ ПРЕСЛЕДОВАНИЕ!
            if size > 15 {
                // БОЛЬШИЕ враги - ОЧЕНЬ агрессивны
                if distance > 20 {
                    let angle = atan2(dy, dx)
                    // Скорость увеличена в 1.5 раза при преследовании
                    velocity.dx = cos(angle) * moveSpeed * 1.5
                    velocity.dy = sin(angle) * moveSpeed * 1.5
                }
            } else {
                // МАЛЕНЬКИЕ враги - убегают если ОЧЕНЬ близко, иначе тоже атакуют
                if distance < 100 {
                    let angle = atan2(dy, dx)
                    velocity.dx = -cos(angle) * moveSpeed
                    velocity.dy = -sin(angle) * moveSpeed
                } else {
                    // Тоже атакуют, но медленнее
                    let angle = atan2(dy, dx)
                    velocity.dx = cos(angle) * moveSpeed * 0.8
                    velocity.dy = sin(angle) * moveSpeed * 0.8
                }
            }
        } else {
            // ВНЕ ВИДИМОСТИ - патрулируют или ищут игрока
            // Медленно движутся в сторону игрока даже издалека
            if distance < aggressionRange * 2 {
                let angle = atan2(dy, dx)
                velocity.dx = cos(angle) * moveSpeed * 0.3
                velocity.dy = sin(angle) * moveSpeed * 0.3
            } else {
                // Случайное патрулирование
                if Int.random(in: 0...100) < 2 {
                    let randomAngle = CGFloat.random(in: 0...(2 * .pi))
                    velocity.dx = cos(randomAngle) * moveSpeed * 0.5
                    velocity.dy = sin(randomAngle) * moveSpeed * 0.5
                }
            }
        }
        
        // Update rotation to face direction
        if velocity.dx != 0 || velocity.dy != 0 {
            let angle = atan2(velocity.dy, velocity.dx)
            self.zRotation = angle
        }
    }
    
    func updatePosition() {
        position.x += velocity.dx
        position.y += velocity.dy
    }
    
    func grow(amount: CGFloat) {
        size += amount
        // При объединении враг становится НАМНОГО быстрее!
        moveSpeed = min(5.0, moveSpeed + 0.3)  // Увеличена макс скорость и прирост
        
        // Recreate shape with new size
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size, y: 0))
        path.addLine(to: CGPoint(x: -size/2, y: size/2))
        path.addLine(to: CGPoint(x: -size/2, y: -size/2))
        path.closeSubpath()
        self.path = path
        
        // Update physics body
        self.physicsBody = SKPhysicsBody(circleOfRadius: size * 0.8)
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.enemy
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.player | GameConfig.PhysicsCategory.enemy
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
    }
    
    func die(theme: ColorTheme) {
        isAlive = false
        
        // Create explosion
        let explosion = ParticleEmitter.createExplosion(at: position, color: theme.skPrimary, count: 15)
        if let parent = self.parent {
            for particle in explosion {
                parent.addChild(particle)
            }
        }
        
        // Remove
        self.removeFromParent()
    }
    
    func updateTheme(_ theme: ColorTheme) {
        self.fillColor = theme.skPrimary.withAlphaComponent(0.8)
        self.strokeColor = theme.skPrimary
    }
}
