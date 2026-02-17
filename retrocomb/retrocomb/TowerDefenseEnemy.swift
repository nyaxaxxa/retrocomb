//
//  TowerDefenseEnemy.swift
//  retrocomb
//
//  Tower Defense Enemy - Level 5
//

import SpriteKit

class TowerDefenseEnemy: SKShapeNode {
    enum EnemyType: CaseIterable {
        case scout
        case bruiser
        case tank
        case disruptor
        case boss
        
        var sizeMultiplier: CGFloat {
            switch self {
            case .scout: return 0.9
            case .bruiser: return 1.1
            case .tank: return 1.35
            case .disruptor: return 1.0
            case .boss: return 1.8
            }
        }
        
        var baseHealth: Int {
            switch self {
            case .scout: return 70
            case .bruiser: return 120
            case .tank: return 220
            case .disruptor: return 150
            case .boss: return 500
            }
        }
        
        var healthGrowth: Int {
            switch self {
            case .scout: return 12
            case .bruiser: return 20
            case .tank: return 32
            case .disruptor: return 24
            case .boss: return 60
            }
        }
        
        var baseDamage: Int {
            switch self {
            case .scout: return 10
            case .bruiser: return 18
            case .tank: return 28
            case .disruptor: return 16
            case .boss: return 45
            }
        }
        
        var damageGrowth: Int {
            switch self {
            case .scout: return 2
            case .bruiser: return 3
            case .tank: return 5
            case .disruptor: return 3
            case .boss: return 8
            }
        }
        
        var baseSpeed: CGFloat {
            switch self {
            case .scout: return 2.8
            case .bruiser: return 2.1
            case .tank: return 1.6
            case .disruptor: return 2.4
            case .boss: return 1.3
            }
        }
        
        var speedGrowth: CGFloat {
            switch self {
            case .scout: return 0.25
            case .bruiser: return 0.18
            case .tank: return 0.12
            case .disruptor: return 0.2
            case .boss: return 0.1
            }
        }
        
        var reward: Int {
            switch self {
            case .scout: return 6
            case .bruiser: return 10
            case .tank: return 16
            case .disruptor: return 12
            case .boss: return 40
            }
        }
        
        var scoreValue: Int {
            switch self {
            case .scout: return 25
            case .bruiser: return 45
            case .tank: return 80
            case .disruptor: return 60
            case .boss: return 200
            }
        }
    }
    
    var health: Int
    var maxHealth: Int
    var moveSpeed: CGFloat
    var damage: Int
    let rewardResources: Int
    let scoreValue: Int
    var isAlive = true
    var enemySize: CGFloat
    var targetPosition: CGPoint
    let enemyType: EnemyType
    var onDeath: ((TowerDefenseEnemy) -> Void)?
    
    private var healthBarBackground: SKShapeNode?
    private var healthBarFill: SKSpriteNode?
    
    init(type: EnemyType, spawnPosition: CGPoint, targetPosition: CGPoint, wave: Int, theme: ColorTheme) {
        enemyType = type
        self.targetPosition = targetPosition
        
        let healthValue = type.baseHealth + wave * type.healthGrowth
        self.health = healthValue
        self.maxHealth = healthValue
        self.moveSpeed = max(type.baseSpeed + type.speedGrowth * CGFloat(wave), 1.0)
        self.damage = type.baseDamage + wave * type.damageGrowth
        self.rewardResources = type.reward
        self.scoreValue = type.scoreValue
        self.enemySize = 18 * type.sizeMultiplier
        
        super.init()
        
        position = spawnPosition
        name = "towerDefenseEnemy"
        zPosition = 15
        isAntialiased = false
        path = CGPath(rect: CGRect(x: -enemySize, y: -enemySize, width: enemySize * 2, height: enemySize * 2), transform: nil)
        fillColor = theme.skPrimary.withAlphaComponent(0.7)
        strokeColor = theme.skAccent
        lineWidth = 2
        glowWidth = type == .boss ? 6 : 3
        
        let faceNode = createFace(theme: theme)
        addChild(faceNode)
        configureHealthBar(theme: theme)
        
        physicsBody = SKPhysicsBody(circleOfRadius: enemySize)
        physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.enemy
        physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        physicsBody?.isDynamic = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    private func createFace(theme: ColorTheme) -> SKNode {
        let node = SKNode()
        let eyeSize = enemySize * 0.32
        let eyeOffset = enemySize * 0.4
        
        func makeEye() -> SKShapeNode {
            let eye = SKShapeNode(rectOf: CGSize(width: eyeSize, height: eyeSize))
            eye.fillColor = theme.skAccent
            eye.strokeColor = .clear
            eye.isAntialiased = false
            eye.zPosition = 1
            return eye
        }
        
        let leftEye = makeEye()
        leftEye.position = CGPoint(x: -eyeOffset, y: enemySize * 0.25)
        node.addChild(leftEye)
        
        let rightEye = makeEye()
        rightEye.position = CGPoint(x: eyeOffset, y: enemySize * 0.25)
        node.addChild(rightEye)
        
        let blink = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 2.0...4.5)),
            SKAction.fadeAlpha(to: 0.1, duration: 0.08),
            SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        ])
        leftEye.run(SKAction.repeatForever(blink))
        rightEye.run(SKAction.repeatForever(blink))
        
        return node
    }
    
    private func configureHealthBar(theme: ColorTheme) {
        let barWidth = enemySize * 1.6
        let barHeight: CGFloat = 5
        let offset = enemySize + 10
        
        let background = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2)
        background.fillColor = theme.skBackground.withAlphaComponent(0.4)
        background.strokeColor = theme.skPrimary.withAlphaComponent(0.6)
        background.lineWidth = 1
        background.position = CGPoint(x: 0, y: offset)
        background.zPosition = 20
        background.isAntialiased = false
        addChild(background)
        
        let fill = SKSpriteNode(color: theme.skAccent, size: CGSize(width: barWidth - 2, height: barHeight - 2))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -barWidth / 2 + 1, y: offset)
        fill.zPosition = 21
        addChild(fill)
        
        healthBarBackground = background
        healthBarFill = fill
        updateHealthBar(theme: theme)
    }
    
    private func updateHealthBar(theme: ColorTheme) {
        guard let fill = healthBarFill else { return }
        let ratio = max(0, min(1, CGFloat(health) / CGFloat(maxHealth)))
        fill.xScale = ratio
        if ratio > 0.6 {
            fill.color = theme.skAccent
        } else if ratio > 0.3 {
            fill.color = theme.skSecondary
        } else {
            fill.color = .red
        }
    }
    
    func updateMovement() {
        guard isAlive else { return }
        let dx = targetPosition.x - position.x
        let dy = targetPosition.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance > 4 {
            let angle = atan2(dy, dx)
            position.x += cos(angle) * moveSpeed
            position.y += sin(angle) * moveSpeed
            zRotation = sin(position.x * 0.08) * 0.08
        }
    }
    
    func takeDamage(_ damage: Int, theme: ColorTheme) {
        guard isAlive else { return }
        health -= damage
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.08),
            SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        ])
        run(flash)
        updateHealthBar(theme: theme)
        if health <= 0 {
            die(theme: theme)
        }
    }
    
    func die(theme: ColorTheme) {
        guard isAlive else { return }
        isAlive = false
        
        // Звук смерти врага
        SoundManager.shared.playSound(.enemyDie, on: self)
        
        let explosion = ParticleEmitter.createExplosion(at: position, color: theme.skPrimary, count: 18)
        if let parent = parent {
            for particle in explosion {
                parent.addChild(particle)
            }
        }
        onDeath?(self)
        removeFromParent()
    }
    
    func hasReachedTarget() -> Bool {
        let distance = hypot(targetPosition.x - position.x, targetPosition.y - position.y)
        return distance < max(enemySize * 0.8, 24)
    }
}

