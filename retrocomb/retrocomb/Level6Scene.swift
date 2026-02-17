import SpriteKit
import UIKit

final class Level6Scene: SKScene {
    private enum ControlType {
        case left
        case right
        case jump
        case fire
    }

    private struct Config {
        static let heroSize = CGSize(width: 70, height: 60)
        static let heroMoveSpeed: CGFloat = 260
        static let heroAirControl: CGFloat = 0.6
        static let heroJumpImpulse: CGFloat = 620
        static let jumpHoldDuration: TimeInterval = 0.22
        static let jumpHoldForce: CGFloat = 420
        static let jetpackThrust: CGFloat = 850  // Сила реактивного ранца при зажатии
        static let gravity: CGFloat = -1350
        static let friction: CGFloat = 0.85

        static let bulletSize = CGSize(width: 26, height: 8)
        static let bulletSpeed: CGFloat = 640
        static let bulletDamage = 40
        static let fireCooldown: TimeInterval = 0.22
        static let initialAmmo = 24
        static let maxAmmo = 60
        static let ammoPickupAmount = 12
        static let ammoSpawnInterval: ClosedRange<TimeInterval> = 4.5...6.5

        static let enemySize = CGSize(width: 72, height: 60)
        static let enemySpeedRange: ClosedRange<CGFloat> = 140...210
        static let enemyHealth = 80
        static let enemyContactDamage = 30
        static let spawnInterval: ClosedRange<TimeInterval> = 1.0...2.0
        static let enemyScore = 12
        static let scoreToWin = 120
        static let heroMaxHealth = GameConfig.Level6.playerMaxHealth
        static let obstacleSpawnInterval: ClosedRange<TimeInterval> = 1.3...2.2
        static let obstacleHeightRange: ClosedRange<CGFloat> = 60...150
        static let obstacleWidthRange: ClosedRange<CGFloat> = 80...210
        static let scrollSpeed: CGFloat = 230
        static let rescueDistance: CGFloat = 4200
    }

    private enum EnemyKind: CaseIterable {
        case crawler
        case brute
        case flyer

        var health: Int {
            switch self {
            case .crawler: return 70
            case .brute: return 140
            case .flyer: return 60
            }
        }

        var speedMultiplier: CGFloat {
            switch self {
            case .crawler: return 1.0
            case .brute: return 0.75
            case .flyer: return 1.3
            }
        }

        var scoreReward: Int {
            switch self {
            case .crawler: return 10
            case .brute: return 20
            case .flyer: return 14
            }
        }

        var tint: UIColor {
            switch self {
            case .crawler: return UIColor.systemMint
            case .brute: return UIColor.systemPink
            case .flyer: return UIColor.systemYellow
            }
        }
    }

    private struct Enemy {
        let node: SKSpriteNode
        var health: Int
        let speed: CGFloat
        let kind: EnemyKind
    }

    private struct Bullet {
        let node: SKSpriteNode
        let velocity: CGVector
    }

    private var theme: ColorTheme = .classicGreen
    private var difficulty: GameConfig.Difficulty = .normal
    private var safeInsets: UIEdgeInsets = .zero

    private var groundY: CGFloat = 0
    private var playableRect: CGRect = .zero

    private var hero: SKSpriteNode!
    private var heroShadow: SKShapeNode!
    private var heroVelocity: CGVector = .zero
    private var isOnGround = false
    private var heroFacingRight = true
    private var jumpHoldTimer: TimeInterval = 0
    private var leftLegNode: SKShapeNode?
    private var rightLegNode: SKShapeNode?
    private var leftArmNode: SKShapeNode?
    private var rightArmNode: SKShapeNode?
    private var torsoNode: SKShapeNode?
    private var backpackFlame: SKNode?

    private var hudNode = SKNode()
    private var backgroundLayer = SKNode()
    private var enemyLayer = SKNode()
    private var obstacleLayer = SKNode()
    private var projectileLayer = SKNode()
    private var heroLayer = SKNode()
    private var controlLayer = SKNode()

    private var controlButtons: [ControlType: SKShapeNode] = [:]
    private var touchAssignments: [UITouch: ControlType] = [:]
    private var isMovingLeft = false
    private var isMovingRight = false
    private var wantsJump = false
    private var isFireHeld = false
    private var isJumpHeld = false

    private var bullets: [Bullet] = []
    private var enemies: [Enemy] = []
    private var obstacles: [SKShapeNode] = []
    private var ammoPickups: [SKShapeNode] = []

    private var spawnTimer: TimeInterval = 1.2
    private var obstacleTimer: TimeInterval = 1.4
    private var ammoTimer: TimeInterval = 5.5
    private var fireCooldown: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0

    private var health: Int = Config.heroMaxHealth
    private var score: Int = 0
    private var ammo: Int = Config.initialAmmo
    private var victoryAchieved = false
    private var isGameOver = false
    private var recordSaved = false
    private var distanceTraveled: CGFloat = 0

    private var scaleFactor: CGFloat = 1

    private var heroSize: CGSize { CGSize(width: Config.heroSize.width * scaleFactor,
                                          height: Config.heroSize.height * scaleFactor) }
    private var enemySize: CGSize { CGSize(width: Config.enemySize.width * scaleFactor,
                                           height: Config.enemySize.height * scaleFactor) }
    private var bulletSize: CGSize { CGSize(width: Config.bulletSize.width * scaleFactor,
                                            height: Config.bulletSize.height * scaleFactor) }

    private var heroMoveSpeedScaled: CGFloat { Config.heroMoveSpeed * scaleFactor }
    private var heroJumpImpulseScaled: CGFloat { Config.heroJumpImpulse * scaleFactor }
    private var bulletSpeedScaled: CGFloat { Config.bulletSpeed * scaleFactor }
    private var enemySpeedRangeScaled: ClosedRange<CGFloat> { (Config.enemySpeedRange.lowerBound * scaleFactor)...(Config.enemySpeedRange.upperBound * scaleFactor) }

    private var healthLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var ammoLabel: SKLabelNode!
    private var stageLabel: SKLabelNode!
    private var infoLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        difficulty = GameData.shared.getCurrentDifficulty()
        safeInsets = view.safeAreaInsets
        backgroundColor = theme.skBackground
        
        // Запускаем фоновую музыку
        SoundManager.shared.playBackgroundMusic(fileName: "retro_music.mp3")

        let widthScale = size.width / GameConfig.screenWidth
        let heightScale = size.height / GameConfig.screenHeight
        scaleFactor = max(0.75, min(1.5, min(widthScale, heightScale)))
        ammo = Config.initialAmmo
        distanceTraveled = 0
        recordSaved = false
        jumpHoldTimer = 0
        spawnTimer = TimeInterval.random(in: Config.spawnInterval)
        obstacleTimer = TimeInterval.random(in: Config.obstacleSpawnInterval)
        ammoTimer = TimeInterval.random(in: Config.ammoSpawnInterval)
        bullets.removeAll()
        enemies.removeAll()

        configureScene()
        setupHUD()
        setupControls()
    }

    private func configureScene() {
        removeAllChildren()

        addChild(backgroundLayer)
        obstacleLayer.zPosition = 11
        enemyLayer.zPosition = 12
        projectileLayer.zPosition = 13
        heroLayer.zPosition = 14
        addChild(obstacleLayer)
        addChild(enemyLayer)
        addChild(projectileLayer)
        addChild(heroLayer)
        addChild(hudNode)
        addChild(controlLayer)
        controlLayer.zPosition = 400

        buildBackdrop()
        setupHero()
    }

    private func buildBackdrop() {
        backgroundLayer.removeAllChildren()

        let width = size.width + safeInsets.left + safeInsets.right
        let height = size.height

        let gradient = SKSpriteNode(color: theme.skBackground.withAlphaComponent(0.9), size: CGSize(width: width * 1.1, height: height))
        gradient.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.position = CGPoint(x: size.width / 2 + (safeInsets.left - safeInsets.right) / 2,
                                    y: size.height / 2)
        gradient.zPosition = -30
        backgroundLayer.addChild(gradient)

        let topGlow = SKShapeNode(rectOf: CGSize(width: width * 1.05, height: height * 0.2))
        topGlow.fillColor = theme.skSecondary.withAlphaComponent(0.18)
        topGlow.strokeColor = .clear
        topGlow.position = CGPoint(x: gradient.position.x, y: size.height - safeInsets.top - 60)
        topGlow.zPosition = -28
        backgroundLayer.addChild(topGlow)

        let starCount = 50
        for _ in 0..<starCount {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0))
            star.fillColor = theme.skPrimary.withAlphaComponent(CGFloat.random(in: 0.2...0.7))
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: safeInsets.left...(size.width - safeInsets.right)),
                                    y: CGFloat.random(in: safeInsets.bottom...(size.height - safeInsets.top)))
            star.zPosition = -25
            backgroundLayer.addChild(star)
            if Bool.random() {
                let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 1.4...3.4))
                let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: Double.random(in: 1.4...3.4))
                star.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
            }
        }

        groundY = safeInsets.bottom + 140 * scaleFactor
        let ground = SKShapeNode(rectOf: CGSize(width: width * 1.2, height: 28 * scaleFactor), cornerRadius: 8 * scaleFactor)
        ground.fillColor = theme.skPrimary.withAlphaComponent(0.38)
        ground.strokeColor = theme.skPrimary
        ground.lineWidth = 2
        ground.position = CGPoint(x: gradient.position.x, y: groundY - 18 * scaleFactor)
        ground.zPosition = -20
        backgroundLayer.addChild(ground)

        let playableWidth = size.width - safeInsets.left - safeInsets.right - DesignSystem.layoutHorizontalPadding * 2
        let minX = safeInsets.left + DesignSystem.layoutHorizontalPadding
        let maxX = minX + playableWidth
        let minY = groundY
        let maxY = size.height - safeInsets.top - 140 * scaleFactor
        playableRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func setupHero() {
        heroLayer.removeAllChildren()
        obstacleLayer.removeAllChildren()
        obstacles.removeAll()
        ammoPickups.removeAll()

        heroShadow = SKShapeNode(ellipseOf: CGSize(width: heroSize.width * 0.7, height: heroSize.height * 0.35))
        heroShadow.fillColor = theme.skBackground.withAlphaComponent(0.55)
        heroShadow.strokeColor = .clear
        heroShadow.position = CGPoint(x: playableRect.minX + heroSize.width * 0.5,
                                      y: groundY - heroSize.height * 0.55)
        heroShadow.zPosition = 5
        heroLayer.addChild(heroShadow)

        hero = SKSpriteNode(color: .clear, size: heroSize)
        hero.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        hero.position = CGPoint(x: playableRect.minX + heroSize.width * 0.6,
                                y: groundY + heroSize.height / 2)
        hero.zPosition = 10
        heroLayer.addChild(hero)

        let uniformColor = theme.skAccent
        let outlineColor = theme.skPrimary.withAlphaComponent(0.85)

        let torso = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.5, height: heroSize.height * 0.45), cornerRadius: 8 * scaleFactor)
        torso.fillColor = uniformColor
        torso.strokeColor = outlineColor
        torso.lineWidth = max(1.8, 2.5 * scaleFactor)
        torso.position = CGPoint(x: 0, y: heroSize.height * 0.05)
        hero.addChild(torso)
        torsoNode = torso

        let head = SKShapeNode(circleOfRadius: heroSize.width * 0.18)
        head.fillColor = theme.skSecondary
        head.strokeColor = outlineColor
        head.lineWidth = max(1.6, 2 * scaleFactor)
        head.position = CGPoint(x: 0, y: heroSize.height * 0.38)
        hero.addChild(head)

        let visor = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.24, height: heroSize.height * 0.08), cornerRadius: 4 * scaleFactor)
        visor.fillColor = theme.skBackground.withAlphaComponent(0.6)
        visor.strokeColor = .clear
        visor.position = CGPoint(x: heroSize.width * 0.04, y: 0)
        head.addChild(visor)

        let leftArm = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.16, height: heroSize.height * 0.4), cornerRadius: 6 * scaleFactor)
        leftArm.fillColor = uniformColor
        leftArm.strokeColor = outlineColor
        leftArm.lineWidth = max(1.6, 2 * scaleFactor)
        leftArm.position = CGPoint(x: -heroSize.width * 0.32, y: heroSize.height * 0.08)
        hero.addChild(leftArm)
        leftArmNode = leftArm

        let rightArm = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.16, height: heroSize.height * 0.4), cornerRadius: 6 * scaleFactor)
        rightArm.fillColor = uniformColor
        rightArm.strokeColor = outlineColor
        rightArm.lineWidth = max(1.6, 2 * scaleFactor)
        rightArm.position = CGPoint(x: heroSize.width * 0.32, y: heroSize.height * 0.08)
        hero.addChild(rightArm)
        rightArmNode = rightArm

        let rifle = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.9, height: heroSize.height * 0.12), cornerRadius: 4 * scaleFactor)
        rifle.fillColor = theme.skBackground
        rifle.strokeColor = outlineColor
        rifle.lineWidth = max(1.6, 2 * scaleFactor)
        rifle.position = CGPoint(x: heroSize.width * 0.3, y: heroSize.height * 0.15)
        rightArm.addChild(rifle)

        let stock = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.18, height: heroSize.height * 0.12))
        stock.fillColor = outlineColor
        stock.strokeColor = .clear
        stock.position = CGPoint(x: -heroSize.width * 0.45, y: 0)
        rifle.addChild(stock)

        let legWidth = heroSize.width * 0.2
        let legHeight = heroSize.height * 0.4
        let leftLeg = SKShapeNode(rectOf: CGSize(width: legWidth, height: legHeight), cornerRadius: 6 * scaleFactor)
        leftLeg.fillColor = uniformColor.withAlphaComponent(0.95)
        leftLeg.strokeColor = outlineColor
        leftLeg.lineWidth = max(1.6, 2 * scaleFactor)
        leftLeg.position = CGPoint(x: -heroSize.width * 0.18, y: -heroSize.height * 0.25)
        hero.addChild(leftLeg)
        leftLegNode = leftLeg

        let rightLeg = SKShapeNode(rectOf: CGSize(width: legWidth, height: legHeight), cornerRadius: 6 * scaleFactor)
        rightLeg.fillColor = uniformColor.withAlphaComponent(0.95)
        rightLeg.strokeColor = outlineColor
        rightLeg.lineWidth = max(1.6, 2 * scaleFactor)
        rightLeg.position = CGPoint(x: heroSize.width * 0.18, y: -heroSize.height * 0.25)
        hero.addChild(rightLeg)
        rightLegNode = rightLeg

        let backpack = SKShapeNode(rectOf: CGSize(width: heroSize.width * 0.3, height: heroSize.height * 0.5), cornerRadius: 6 * scaleFactor)
        backpack.fillColor = theme.skAccent.withAlphaComponent(0.7)
        backpack.strokeColor = outlineColor
        backpack.lineWidth = max(1.6, 2 * scaleFactor)
        backpack.position = CGPoint(x: -heroSize.width * 0.25, y: heroSize.height * 0.1)
        hero.addChild(backpack)

        backpackFlame = SKNode()
        backpackFlame?.position = CGPoint(x: -heroSize.width * 0.45, y: heroSize.height * 0.05)
        hero.addChild(backpackFlame!)
        startFlameAnimation()
        backpackFlame?.isHidden = true

        heroVelocity = .zero
        isOnGround = true
        heroFacingRight = true

        startRunAnimation()
    }

    private func setupHUD() {
        hudNode.removeAllChildren()

        let topY = size.height - safeInsets.top - DesignSystem.layoutVerticalPadding
        let leftX = safeInsets.left + DesignSystem.layoutHorizontalPadding
        let rightX = size.width - safeInsets.right - DesignSystem.layoutHorizontalPadding
        let centerX = size.width / 2 + (safeInsets.left - safeInsets.right) / 2
        let bottomInfoY = safeInsets.bottom + DesignSystem.layoutVerticalPadding * 1.2 + 120 * scaleFactor

        healthLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(healthLabel, style: .body, theme: theme, alignment: .left)
        healthLabel.position = CGPoint(x: leftX, y: topY)
        healthLabel.preferredMaxLayoutWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 200)
        wrapLabel(healthLabel, maxWidth: healthLabel.preferredMaxLayoutWidth)
        hudNode.addChild(healthLabel)

        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(scoreLabel, style: .body, theme: theme, alignment: .right)
        scoreLabel.position = CGPoint(x: rightX, y: topY)
        scoreLabel.preferredMaxLayoutWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 200)
        wrapLabel(scoreLabel, maxWidth: scoreLabel.preferredMaxLayoutWidth)
        hudNode.addChild(scoreLabel)

        ammoLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(ammoLabel, style: .body, theme: theme, alignment: .right)
        ammoLabel.fontColor = theme.skSecondary
        ammoLabel.position = CGPoint(x: rightX,
                                     y: scoreLabel.position.y - (scoreLabel.frame.height + DesignSystem.layoutInterItemSpacing / 1.5))
        ammoLabel.preferredMaxLayoutWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 200)
        hudNode.addChild(ammoLabel)

        stageLabel = SKLabelNode(fontNamed: "Courier")
        DesignSystem.apply(stageLabel, style: .subtitle, theme: theme)
        stageLabel.text = "Неон-Коридор"
        stageLabel.position = CGPoint(x: centerX,
                                      y: topY - (healthLabel.frame.height + DesignSystem.layoutInterItemSpacing))
        hudNode.addChild(stageLabel)

        infoLabel = SKLabelNode(fontNamed: "Courier")
        DesignSystem.apply(infoLabel, style: .footnote, theme: theme)
        infoLabel.fontColor = theme.skSecondary
        infoLabel.position = CGPoint(x: centerX,
                                     y: bottomInfoY)
        hudNode.addChild(infoLabel)

        updateHUD()
    }

    private func setupControls() {
        controlLayer.removeAllChildren()
        controlButtons = [:]
        touchAssignments = [:]

        let horizontalPadding = DesignSystem.layoutHorizontalPadding + 24 * scaleFactor
        let verticalPadding = DesignSystem.layoutVerticalPadding + 28 * scaleFactor
        let usableWidth = size.width - safeInsets.left - safeInsets.right - horizontalPadding * 2

        // Минимальный размер кнопки для удобства нажатия
        let minButtonSize: CGFloat = 60 * scaleFactor
        // Максимальный размер кнопки
        let maxButtonSize: CGFloat = 120 * scaleFactor
        
        // Вычисляем базовый размер с учетом доступного пространства
        let base = min(max(minButtonSize, usableWidth / 6.5), maxButtonSize)
        let buttonSize = CGSize(width: base, height: base)
        let jumpSize = CGSize(width: base * 1.05, height: base * 1.05)
        let fireSize = CGSize(width: base * 1.25, height: base * 1.1)

        let sequence: [(ControlType, CGSize)] = [(.jump, jumpSize),
                                                 (.fire, fireSize),
                                                 (.right, buttonSize),
                                                 (.left, buttonSize)]
        
        // Вычисляем минимальный spacing
        let minSpacing: CGFloat = max(12 * scaleFactor, base * 0.15)
        let totalWidth = sequence.reduce(0) { partial, entry in partial + entry.1.width } + minSpacing * CGFloat(sequence.count - 1)
        
        // Если кнопки не помещаются, уменьшаем размеры
        var finalBase = base
        var finalSpacing = minSpacing
        if totalWidth > usableWidth {
            // Вычисляем масштаб для умещения всех кнопок
            let scale = usableWidth / totalWidth
            finalBase = max(minButtonSize, base * scale)
            finalSpacing = max(8 * scaleFactor, minSpacing * scale)
            
            // Пересчитываем размеры с новым базовым размером
            let newButtonSize = CGSize(width: finalBase, height: finalBase)
            let newJumpSize = CGSize(width: finalBase * 1.05, height: finalBase * 1.05)
            let newFireSize = CGSize(width: finalBase * 1.25, height: finalBase * 1.1)
            
            let newSequence: [(ControlType, CGSize)] = [(.jump, newJumpSize),
                                                         (.fire, newFireSize),
                                                         (.right, newButtonSize),
                                                         (.left, newButtonSize)]
            
            let baselineY = safeInsets.bottom + verticalPadding
            let maxHeight = newSequence.map { $0.1.height }.max() ?? newButtonSize.height
            let centerX = size.width / 2 + (safeInsets.left - safeInsets.right) / 2
            let newTotalWidth = newSequence.reduce(0) { partial, entry in partial + entry.1.width } + finalSpacing * CGFloat(newSequence.count - 1)
            let startX = centerX - newTotalWidth / 2

            var cursorX = startX
            for (type, size) in newSequence {
                let button = createControlButton(size: size, type: type)
                button.position = CGPoint(x: cursorX + size.width / 2,
                                          y: baselineY + maxHeight / 2)
                cursorX += size.width + finalSpacing
            }

            if let infoLabel {
                infoLabel.position = CGPoint(x: centerX,
                                             y: baselineY + maxHeight + finalSpacing * 1.2)
            }
        } else {
            let baselineY = safeInsets.bottom + verticalPadding
            let maxHeight = sequence.map { $0.1.height }.max() ?? buttonSize.height
            let centerX = size.width / 2 + (safeInsets.left - safeInsets.right) / 2
            let startX = centerX - totalWidth / 2

            var cursorX = startX
            for (type, size) in sequence {
                let button = createControlButton(size: size, type: type)
                button.position = CGPoint(x: cursorX + size.width / 2,
                                          y: baselineY + maxHeight / 2)
                cursorX += size.width + finalSpacing
            }

            if let infoLabel {
                infoLabel.position = CGPoint(x: centerX,
                                             y: baselineY + maxHeight + finalSpacing * 1.2)
            }
        }

        updateControlHighlights()
    }

    private func createControlButton(size: CGSize, type: ControlType) -> SKShapeNode {
        let cornerRadius = size.height * 0.28
        let button = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        button.fillColor = theme.skAccent.withAlphaComponent(0.25)
        button.strokeColor = theme.skPrimary
        button.lineWidth = max(3.5, size.height * 0.08)
        button.glowWidth = max(4.5, size.height * 0.12)
        button.name = "control_\(type)"
        button.zPosition = 15
        addIcon(for: type, to: button, size: size)

        controlLayer.addChild(button)
        controlButtons[type] = button
        return button
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }

        let deltaTime = max(0.001, lastUpdateTime == 0 ? 0.016 : currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        updateFireCooldown(deltaTime: deltaTime)
        updateHero(deltaTime: deltaTime)
        updateBullets(deltaTime: deltaTime)
        updateEnemies(deltaTime: deltaTime)
        updateObstacles(deltaTime: deltaTime)
        updateAmmoPickups(deltaTime: deltaTime)

        distanceTraveled += Config.scrollSpeed * CGFloat(deltaTime)

        spawnTimer -= deltaTime
        if spawnTimer <= 0 {
            spawnEnemy()
            spawnTimer = TimeInterval.random(in: Config.spawnInterval)
        }

        obstacleTimer -= deltaTime
        if obstacleTimer <= 0 {
            spawnObstacle()
            obstacleTimer = TimeInterval.random(in: Config.obstacleSpawnInterval)
        }

        ammoTimer -= deltaTime
        if ammoTimer <= 0 {
            spawnAmmoPickup()
            ammoTimer = TimeInterval.random(in: Config.ammoSpawnInterval)
        }

        evaluateWinLose()
        updateHUD()
    }

    private func updateFireCooldown(deltaTime: TimeInterval) {
        fireCooldown = max(0, fireCooldown - deltaTime)
        if fireCooldown <= 0, isFireHeld {
            fireWeapon()
        }
    }

    private func updateHero(deltaTime: TimeInterval) {
        let controlFactor: CGFloat = isOnGround ? 1.0 : Config.heroAirControl

        if isMovingLeft && !isMovingRight {
            heroVelocity.dx = lerp(heroVelocity.dx, target: -heroMoveSpeedScaled, t: 0.2 * controlFactor)
            if heroFacingRight { hero.xScale = -1; heroFacingRight = false }
        } else if isMovingRight && !isMovingLeft {
            heroVelocity.dx = lerp(heroVelocity.dx, target: heroMoveSpeedScaled, t: 0.2 * controlFactor)
            if !heroFacingRight { hero.xScale = 1; heroFacingRight = true }
        } else {
            heroVelocity.dx *= Config.friction
            if abs(heroVelocity.dx) < 1 { heroVelocity.dx = 0 }
        }

        if wantsJump {
            wantsJump = false
            if isOnGround {
                heroVelocity.dy = heroJumpImpulseScaled
                isOnGround = false
                jumpHoldTimer = Config.jumpHoldDuration
            }
        }

        heroVelocity.dy += Config.gravity * CGFloat(deltaTime)
        heroVelocity.dy = max(heroVelocity.dy, Config.gravity)

        // Реактивный ранец: при зажатии кнопки прыжка применяем постоянную силу вверх
        if isJumpHeld {
            heroVelocity.dy += Config.jetpackThrust * CGFloat(deltaTime)
            // Также применяем дополнительную силу при начальном прыжке
            if jumpHoldTimer > 0 {
                heroVelocity.dy += Config.jumpHoldForce * CGFloat(deltaTime)
                jumpHoldTimer -= deltaTime
            }
        } else {
            jumpHoldTimer = 0
        }

        hero.position.x += heroVelocity.dx * CGFloat(deltaTime)
        hero.position.x = min(max(hero.position.x, playableRect.minX + heroSize.width / 2), playableRect.maxX - heroSize.width / 2)

        hero.position.y += heroVelocity.dy * CGFloat(deltaTime)
        if hero.position.y <= groundY + heroSize.height / 2 {
            hero.position.y = groundY + heroSize.height / 2
            heroVelocity.dy = 0
            isOnGround = true
            jumpHoldTimer = 0
        } else if hero.position.y > playableRect.maxY {
            hero.position.y = playableRect.maxY
            heroVelocity.dy = 0
        } else {
            isOnGround = false
        }

        heroShadow.position.x = hero.position.x
        let shadowOffset = max(0, hero.position.y - (groundY + heroSize.height / 2)) * 0.05
        heroShadow.position.y = groundY - heroSize.height * 0.55 + shadowOffset
        updateBackpackFlame()
    }

    private func updateBullets(deltaTime: TimeInterval) {
        for (index, bullet) in bullets.enumerated().reversed() {
            bullet.node.position.x += bullet.velocity.dx * CGFloat(deltaTime)
            if bullet.node.position.x < -bullet.node.frame.width || bullet.node.position.x > size.width + bullet.node.frame.width {
                bullet.node.removeFromParent()
                bullets.remove(at: index)
                continue
            }

            for enemyIndex in enemies.indices.reversed() {
                if bullet.node.frame.intersects(enemies[enemyIndex].node.frame) {
                    bullet.node.removeFromParent()
                    bullets.remove(at: index)
                    damageEnemy(at: enemyIndex)
                    break
                }
            }
        }
    }

    private func updateEnemies(deltaTime: TimeInterval) {
        for index in enemies.indices.reversed() {
            let node = enemies[index].node
            let speed = enemies[index].speed + Config.scrollSpeed * 0.3
            node.position.x -= speed * CGFloat(deltaTime)
            let bobAmplitude: CGFloat = enemies[index].kind == .flyer ? 16 * scaleFactor : 4 * scaleFactor
            let bob = sin(CGFloat(lastUpdateTime) * 5 + node.position.x * 0.04) * bobAmplitude
            let baseY = enemies[index].kind == .flyer ? groundY + enemySize.height * 1.6 : groundY + enemySize.height / 2
            node.position.y = baseY + bob

            if node.frame.intersects(hero.frame) {
                applyDamage(amount: Config.enemyContactDamage)
                removeEnemy(at: index)
                continue
            }

            if node.position.x < -node.frame.width {
                removeEnemy(at: index)
            }
        }
    }

    private func spawnObstacle() {
        let width = CGFloat.random(in: Config.obstacleWidthRange) * scaleFactor
        let height = CGFloat.random(in: Config.obstacleHeightRange) * scaleFactor
        let obstacle = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12 * scaleFactor)
        obstacle.fillColor = theme.skPrimary.withAlphaComponent(0.55)
        obstacle.strokeColor = theme.skSecondary
        obstacle.lineWidth = 2.0
        obstacle.position = CGPoint(x: size.width + width / 2,
                                    y: groundY + height / 2)
        obstacle.zPosition = 8
        obstacleLayer.addChild(obstacle)
        obstacles.append(obstacle)
    }

    private func updateObstacles(deltaTime: TimeInterval) {
        for (index, obstacle) in obstacles.enumerated().reversed() {
            obstacle.position.x -= Config.scrollSpeed * CGFloat(deltaTime)
            if obstacle.position.x < -obstacle.frame.width {
                obstacle.removeFromParent()
                obstacles.remove(at: index)
                continue
            }

            if obstacle.frame.intersects(hero.frame.insetBy(dx: heroSize.width * -0.05, dy: 0)) {
                applyDamage(amount: 20)
                obstacle.removeFromParent()
                obstacles.remove(at: index)
                heroVelocity.dy = heroJumpImpulseScaled * 0.6
                isOnGround = false
            }
        }
    }

    private func spawnAmmoPickup() {
        let pickupSize = CGSize(width: 36 * scaleFactor, height: 36 * scaleFactor)
        let pickup = SKShapeNode(rectOf: pickupSize, cornerRadius: 6 * scaleFactor)
        pickup.fillColor = theme.skAccent.withAlphaComponent(0.9)
        pickup.strokeColor = theme.skPrimary
        pickup.lineWidth = 2
        pickup.position = CGPoint(x: size.width + pickupSize.width,
                                  y: groundY + heroSize.height * CGFloat.random(in: 0.2...0.8))
        pickup.zPosition = 11

        let bulletIcon = SKShapeNode(rectOf: CGSize(width: pickupSize.width * 0.2, height: pickupSize.height * 0.7), cornerRadius: 4 * scaleFactor)
        bulletIcon.fillColor = theme.skBackground
        bulletIcon.strokeColor = .clear
        pickup.addChild(bulletIcon)

        obstacleLayer.addChild(pickup)
        ammoPickups.append(pickup)
    }

    private func updateAmmoPickups(deltaTime: TimeInterval) {
        for (index, pickup) in ammoPickups.enumerated().reversed() {
            pickup.position.x -= Config.scrollSpeed * CGFloat(deltaTime)
            if pickup.position.x < -pickup.frame.width {
                pickup.removeFromParent()
                ammoPickups.remove(at: index)
                continue
            }

            if pickup.frame.intersects(hero.frame) {
                ammo = min(Config.maxAmmo, ammo + Config.ammoPickupAmount)
                pickup.removeFromParent()
                ammoPickups.remove(at: index)
                updateHUD()
            }
        }
    }

    private func spawnEnemy() {
        let kind = EnemyKind.allCases.randomElement() ?? .crawler
        let node = SKSpriteNode(color: .clear, size: enemySize)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.position = CGPoint(x: size.width + enemySize.width,
                                y: groundY + enemySize.height / 2)
        if kind == .flyer {
            node.position.y = groundY + enemySize.height * 1.8
        }
        node.zPosition = 12

        let bodyWidth = enemySize.width * 0.82
        let bodyHeight = enemySize.height * 0.75
        let body = SKShapeNode(rectOf: CGSize(width: bodyWidth, height: bodyHeight), cornerRadius: enemySize.width * 0.24)
        body.name = "monster_body"
        body.fillColor = kind.tint.withAlphaComponent(0.85)
        body.strokeColor = theme.skPrimary
        body.lineWidth = max(2.5, 4 * scaleFactor)
        body.glowWidth = max(4.5, 6 * scaleFactor)
        body.position = .zero
        node.addChild(body)

        let hornHeight = enemySize.height * 0.35
        let hornWidth = enemySize.width * 0.18
        let leftHornPath = CGMutablePath()
        leftHornPath.move(to: CGPoint(x: -bodyWidth / 2 + hornWidth * 0.2, y: bodyHeight / 2 - hornHeight * 0.25))
        leftHornPath.addLine(to: CGPoint(x: -bodyWidth / 2 - hornWidth * 0.2, y: bodyHeight / 2 + hornHeight * 0.6))
        leftHornPath.addLine(to: CGPoint(x: -bodyWidth / 2 + hornWidth * 0.6, y: bodyHeight / 2 + hornHeight * 0.05))
        leftHornPath.closeSubpath()
        let leftHorn = SKShapeNode(path: leftHornPath)
        leftHorn.fillColor = theme.skAccent.withAlphaComponent(0.7)
        leftHorn.strokeColor = theme.skPrimary
        leftHorn.lineWidth = max(2, 3 * scaleFactor)
        body.addChild(leftHorn)

        let rightHorn = leftHorn.copy() as! SKShapeNode
        rightHorn.xScale = -1
        body.addChild(rightHorn)

        let eyeRadius = enemySize.width * 0.13
        let leftEye = SKShapeNode(circleOfRadius: eyeRadius)
        leftEye.fillColor = theme.skBackground
        leftEye.strokeColor = theme.skPrimary.withAlphaComponent(0.6)
        leftEye.lineWidth = max(1.5, 2.5 * scaleFactor)
        leftEye.position = CGPoint(x: -bodyWidth * 0.2, y: eyeRadius * 1.4)
        body.addChild(leftEye)

        let rightEye = leftEye.copy() as! SKShapeNode
        rightEye.position.x = bodyWidth * 0.2
        body.addChild(rightEye)

        let pupilRadius = eyeRadius * 0.45
        let leftPupil = SKShapeNode(circleOfRadius: pupilRadius)
        leftPupil.fillColor = theme.skAccent
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0, y: -pupilRadius * 0.2)
        leftEye.addChild(leftPupil)

        let rightPupil = leftPupil.copy() as! SKShapeNode
        rightEye.addChild(rightPupil)

        let mouth = SKShapeNode(rectOf: CGSize(width: bodyWidth * 0.46, height: enemySize.height * 0.18), cornerRadius: enemySize.height * 0.08)
        mouth.fillColor = theme.skBackground.withAlphaComponent(0.7)
        mouth.strokeColor = theme.skPrimary
        mouth.lineWidth = max(1.5, 2.5 * scaleFactor)
        mouth.position = CGPoint(x: 0, y: -enemySize.height * 0.14)
        body.addChild(mouth)

        let toothWidth = mouth.frame.width * 0.18
        let toothHeight = enemySize.height * 0.12
        for offset in [-1, 1] {
            let toothPath = CGMutablePath()
            toothPath.move(to: CGPoint(x: CGFloat(offset) * toothWidth * 0.4, y: mouth.frame.height / 2))
            toothPath.addLine(to: CGPoint(x: CGFloat(offset) * toothWidth * 0.8, y: mouth.frame.height / 2))
            toothPath.addLine(to: CGPoint(x: CGFloat(offset) * toothWidth * 0.6, y: mouth.frame.height / 2 - toothHeight))
            toothPath.closeSubpath()
            let tooth = SKShapeNode(path: toothPath)
            tooth.fillColor = theme.skAccent
            tooth.strokeColor = theme.skPrimary.withAlphaComponent(0.6)
            tooth.lineWidth = max(1, 1.5 * scaleFactor)
            mouth.addChild(tooth)
        }

        enemyLayer.addChild(node)

        let baseSpeed = CGFloat.random(in: enemySpeedRangeScaled) * kind.speedMultiplier + Config.scrollSpeed * 0.25
        enemies.append(Enemy(node: node, health: kind.health, speed: baseSpeed, kind: kind))
    }

    private func fireWeapon() {
        guard fireCooldown <= 0 else { return }
        guard ammo > 0 else { return }
        let speedFactor = max(0.8, min(1.2, difficulty.speedMultiplier))
        fireCooldown = Config.fireCooldown / TimeInterval(speedFactor)
        ammo -= 1
        updateHUD()
        
        // Звук выстрела
        SoundManager.shared.playSound(.shoot, on: self)

        let direction: CGFloat = heroFacingRight ? 1 : -1
        let bullet = SKSpriteNode(color: theme.skPrimary, size: bulletSize)
        bullet.anchorPoint = CGPoint(x: heroFacingRight ? 0 : 1, y: 0.5)
        bullet.position = CGPoint(x: hero.position.x + direction * (heroSize.width / 2 + 4 * scaleFactor),
                                  y: hero.position.y + heroSize.height * 0.1)
        bullet.zPosition = 14
        projectileLayer.addChild(bullet)

        bullets.append(Bullet(node: bullet, velocity: CGVector(dx: bulletSpeedScaled * direction, dy: 0)))

        if let fireButton = controlButtons[.fire] {
            fireButton.removeAction(forKey: "firePulse")
            let pulseUp = SKAction.scale(to: 1.05, duration: 0.08)
            pulseUp.timingMode = .easeOut
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.12)
            pulseDown.timingMode = .easeIn
            fireButton.run(SKAction.sequence([pulseUp, pulseDown]), withKey: "firePulse")
        }
    }

    private func damageEnemy(at index: Int) {
        guard enemies.indices.contains(index) else { return }
        enemies[index].health -= Config.bulletDamage
        if enemies[index].health <= 0 {
            // Звук смерти врага
            SoundManager.shared.playSound(.enemyDie, on: self)
            score += enemies[index].kind.scoreReward
            let node = enemies[index].node
            let burst = RetroEffects.createNeonTrail(from: node.position, color: theme.skAccent, size: 30)
            burst.zPosition = node.zPosition + 1
            enemyLayer.addChild(burst)
            burst.run(SKAction.sequence([SKAction.wait(forDuration: 0.4), .removeFromParent()]))
            removeEnemy(at: index)
        } else {
            // Звук попадания
            SoundManager.shared.playSound(.hit, on: self)
            if let body = enemies[index].node.childNode(withName: "monster_body") as? SKShapeNode {
                let original = theme.skSecondary.withAlphaComponent(0.88)
                let accent = theme.skAccent.withAlphaComponent(0.95)
                let flashUp = SKAction.run { body.fillColor = accent }
                let flashDown = SKAction.run { body.fillColor = original }
                body.run(SKAction.sequence([flashUp,
                                            SKAction.wait(forDuration: 0.12),
                                            flashDown]), withKey: "monsterFlash")
            }
        }
    }

    private func removeEnemy(at index: Int) {
        guard enemies.indices.contains(index) else { return }
        enemies[index].node.removeAllActions()
        enemies[index].node.removeFromParent()
        enemies.remove(at: index)
    }

    private func applyDamage(amount: Int) {
        guard !isGameOver else { return }
        health = max(0, health - amount)
        
        // Звук получения урона
        SoundManager.shared.playSound(.hit, on: self)
        
        let hitFlash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.6, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
        ])
        hero.run(hitFlash)
    }

    private func evaluateWinLose() {
        if health <= 0 {
            triggerDefeat()
        } else if distanceTraveled >= Config.rescueDistance {
            triggerVictory()
        }
    }

    private func updateHUD() {
        healthLabel.text = "HP: \(max(0, health))"
        wrapLabel(healthLabel, maxWidth: healthLabel.preferredMaxLayoutWidth)

        scoreLabel.text = "Score: \(score)"
        wrapLabel(scoreLabel, maxWidth: scoreLabel.preferredMaxLayoutWidth)

        ammoLabel.text = "Ammo: \(ammo)/\(Config.maxAmmo)"
        wrapLabel(ammoLabel, maxWidth: ammoLabel.preferredMaxLayoutWidth)

        let remainingDistance = max(0, Int((Config.rescueDistance - distanceTraveled).rounded()))
        if isGameOver && victoryAchieved {
            infoLabel.text = "Эвакуация завершена."
        } else if isGameOver {
            infoLabel.text = "Пилот потерян. Попробуй ещё."
        } else {
            infoLabel.text = "До эвакуации: \(remainingDistance) м"
        }
        wrapLabel(infoLabel, maxWidth: infoLabel.preferredMaxLayoutWidth)
    }

    private func triggerVictory() {
        guard !isGameOver else { return }
        isGameOver = true
        victoryAchieved = true
        GameData.shared.updateLevelRecord(level: 6, score: score)
        setControlsVisible(false)
        let message = "ПОСТМОРТЕМ: Пилот эвакуирован. Спасение завершено, кампания пройдена. Счёт: \(score)"
        showOverlay(message: message,
                    buttons: [("📝 ЗАПИСЬ", "record"), ("↻ ЗАНОВО", "retry"), ("◄ МЕНЮ", "menu")])
    }

    private func triggerDefeat() {
        guard !isGameOver else { return }
        isGameOver = true
        victoryAchieved = false
        GameData.shared.updateLevelRecord(level: 6, score: score)
        setControlsVisible(false)
        showOverlay(message: StoryManager.shared.randomPostmortem(),
                    buttons: [("↻ ЗАНОВО", "retry"), ("◄ МЕНЮ", "menu")])
    }

    private func setControlsVisible(_ visible: Bool) {
        controlLayer.alpha = visible ? 1 : 0
        isMovingLeft = false
        isMovingRight = false
        wantsJump = false
        isFireHeld = false
        isJumpHeld = false
        if !visible {
            jumpHoldTimer = 0
            backpackFlame?.isHidden = true
        }
        touchAssignments.removeAll()
        updateControlHighlights()
    }

    private func showOverlay(message: String, buttons: [(String, String)]) {
        let configs = buttons.map { OverlayButtonConfig(title: $0.0, name: $0.1) }
        OverlayFactory.presentModal(on: self,
                                    scene: self,
                                    theme: theme,
                                    message: message,
                                    buttons: configs,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }

    private func handleOverlayTap(at point: CGPoint) {
        let nodes = nodes(at: point)
        for node in nodes {
            guard let name = node.name else { continue }
            switch name {
            case "retry":
                let nextSize = view?.bounds.size ?? size
                let scene = Level6Scene(size: nextSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
            case "menu":
                // Переход в меню - если победа, показываем финальную катсцену, иначе сразу в меню
                if victoryAchieved {
                    StoryManager.shared.presentPostLevelCutscene(from: self, level: 6, victory: true)
                } else {
                    // Прямой переход в меню при поражении
                    let menuSize = view?.bounds.size ?? size
                    let menuScene = MenuScene(size: menuSize)
                    menuScene.scaleMode = .resizeFill
                    view?.presentScene(menuScene, transition: .fade(withDuration: 0.5))
                }
            case "record":
                recordRescue()
            default:
                continue
            }
        }
    }

    private func recordRescue() {
        guard victoryAchieved, !recordSaved else { return }
        recordSaved = true
        
        // Сохраняем запись в таблицу рекордов
        GameData.shared.addLeaderboardEntry(name: "СПАСАТЕЛЬ", score: score, level: 6)
        
        // Принудительно синхронизируем UserDefaults
        UserDefaults.standard.synchronize()
        
        // Удаляем старый overlay
        childNode(withName: "//modal_dim")?.removeFromParent()
        childNode(withName: "//modal_card")?.removeFromParent()
        
        // Показываем подтверждение с кнопками
        showOverlay(message: "Запись о подвиге сохранена. Имя героя занесено в хроники.",
                    buttons: [("↻ ЗАНОВО", "retry"), ("◄ МЕНЮ", "menu")])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            guard let point = touches.first?.location(in: self) else { return }
            handleOverlayTap(at: point)
            return
        }
        handleTouches(touches, began: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        for touch in touches {
            guard let control = touchAssignments[touch], let button = controlButtons[control] else { continue }
            let isInside = button.contains(touch.location(in: controlLayer))
            if !isInside {
                touchAssignments[touch] = nil
                updateControlState(for: control, pressed: false)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        handleTouches(touches, began: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, began: false)
    }

    private func handleTouches(_ touches: Set<UITouch>, began: Bool) {
        for touch in touches {
            if began {
                guard let control = control(at: touch.location(in: controlLayer)) else { continue }
                touchAssignments[touch] = control
                updateControlState(for: control, pressed: true)
                if control == .fire && fireCooldown <= 0 { fireWeapon() }
            } else {
                if let control = touchAssignments[touch] {
                    updateControlState(for: control, pressed: false)
                }
                touchAssignments[touch] = nil
            }
        }
        updateControlHighlights()
    }

    private func control(at point: CGPoint) -> ControlType? {
        for (type, button) in controlButtons where button.contains(point) {
            return type
        }
        return nil
    }

    private func addIcon(for type: ControlType, to button: SKShapeNode, size: CGSize) {
        let icon: SKShapeNode
        switch type {
        case .left:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: size.width * 0.15, y: 0))
            path.addLine(to: CGPoint(x: -size.width * 0.2, y: size.height * 0.25))
            path.addLine(to: CGPoint(x: -size.width * 0.2, y: -size.height * 0.25))
            path.closeSubpath()
            icon = SKShapeNode(path: path)
        case .right:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size.width * 0.15, y: 0))
            path.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.25))
            path.addLine(to: CGPoint(x: size.width * 0.2, y: -size.height * 0.25))
            path.closeSubpath()
            icon = SKShapeNode(path: path)
        case .jump:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size.width * 0.25, y: -size.height * 0.1))
            path.addLine(to: CGPoint(x: 0, y: size.height * 0.25))
            path.addLine(to: CGPoint(x: size.width * 0.25, y: -size.height * 0.1))
            path.closeSubpath()
            icon = SKShapeNode(path: path)
        case .fire:
            let outer = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.22)
            outer.fillColor = theme.skPrimary
            outer.strokeColor = .clear
            let inner = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.08)
            inner.fillColor = theme.skBackground
            inner.strokeColor = .clear
            inner.name = "icon_inner"
            outer.addChild(inner)
            icon = outer
        }
        icon.name = "icon_shape"
        icon.fillColor = (type == .fire) ? icon.fillColor : theme.skPrimary
        icon.strokeColor = .clear
        button.addChild(icon)
    }

    private func startRunAnimation() {
        let swingAngle = CGFloat.pi / 10
        let backAngle = -CGFloat.pi / 10
        let duration = 0.18

        let forward = SKAction.rotate(toAngle: swingAngle, duration: duration)
        let backward = SKAction.rotate(toAngle: backAngle, duration: duration)
        forward.timingMode = .easeInEaseOut
        backward.timingMode = .easeInEaseOut

        if let leftLegNode {
            leftLegNode.removeAction(forKey: "run_cycle")
            let sequence = SKAction.sequence([forward, backward])
            leftLegNode.run(SKAction.repeatForever(sequence), withKey: "run_cycle")
        }

        if let rightLegNode {
            rightLegNode.removeAction(forKey: "run_cycle")
            let sequence = SKAction.sequence([backward, forward])
            rightLegNode.run(SKAction.repeatForever(sequence), withKey: "run_cycle")
        }

        if let leftArmNode {
            leftArmNode.removeAction(forKey: "run_cycle")
            let armSequence = SKAction.sequence([backward, forward])
            leftArmNode.run(SKAction.repeatForever(armSequence), withKey: "run_cycle")
        }

        if let rightArmNode {
            rightArmNode.removeAction(forKey: "run_cycle")
            let armSequence = SKAction.sequence([forward, backward])
            rightArmNode.run(SKAction.repeatForever(armSequence), withKey: "run_cycle")
        }

        if let torsoNode {
            torsoNode.removeAction(forKey: "run_bob")
            let bobUp = SKAction.moveBy(x: 0, y: 4 * scaleFactor, duration: 0.15)
            let bobDown = SKAction.moveBy(x: 0, y: -4 * scaleFactor, duration: 0.15)
            bobUp.timingMode = .easeInEaseOut
            bobDown.timingMode = .easeInEaseOut
            let bobSequence = SKAction.sequence([bobUp, bobDown])
            torsoNode.run(SKAction.repeatForever(bobSequence), withKey: "run_bob")
        }
    }

    private func updateControlState(for control: ControlType, pressed: Bool) {
        switch control {
        case .left:
            isMovingLeft = pressed
        case .right:
            isMovingRight = pressed
        case .jump:
            if pressed && !isJumpHeld { wantsJump = true }
            if !pressed { jumpHoldTimer = 0 }
            isJumpHeld = pressed
        case .fire:
            isFireHeld = pressed
        }
    }

    private func updateControlHighlights() {
        for (type, button) in controlButtons {
            let pressed: Bool
            switch type {
            case .left: pressed = isMovingLeft
            case .right: pressed = isMovingRight
            case .jump: pressed = isJumpHeld
            case .fire: pressed = isFireHeld
            }
            button.fillColor = pressed ? theme.skAccent.withAlphaComponent(0.55) : theme.skAccent.withAlphaComponent(0.25)
            button.strokeColor = pressed ? theme.skBackground : theme.skPrimary
            if let iconShape = button.childNode(withName: "icon_shape") as? SKShapeNode {
                if type == .fire {
                    iconShape.fillColor = pressed ? theme.skSecondary : theme.skPrimary
                    if let inner = iconShape.childNode(withName: "icon_inner") as? SKShapeNode {
                        inner.fillColor = pressed ? theme.skBackground : theme.skBackground
                    }
                } else {
                    iconShape.fillColor = pressed ? theme.skBackground : theme.skPrimary
                }
            }
        }
    }

    private func startFlameAnimation() {
        guard let backpackFlame else { return }
        backpackFlame.removeAction(forKey: "flame_emit")
        let spawn = SKAction.run { [weak self] in self?.emitFlameParticle() }
        let wait = SKAction.wait(forDuration: 0.05)
        backpackFlame.run(SKAction.repeatForever(SKAction.sequence([spawn, wait])), withKey: "flame_emit")
    }

    private func emitFlameParticle() {
        guard let backpackFlame, backpackFlame.isHidden == false else { return }
        let radius = heroSize.width * 0.08
        let particle = SKShapeNode(circleOfRadius: radius)
        particle.fillColor = theme.skAccent.withAlphaComponent(CGFloat.random(in: 0.5...0.9))
        particle.strokeColor = .clear
        particle.position = .zero
        particle.alpha = 0.9
        particle.zPosition = -1
        backpackFlame.addChild(particle)

        let horizontal = (heroFacingRight ? -1 : 1) * heroSize.width * CGFloat.random(in: 0.1...0.25)
        let vertical = -heroSize.height * CGFloat.random(in: 0.25...0.4)
        let move = SKAction.moveBy(x: horizontal, y: vertical, duration: 0.25)
        let fade = SKAction.fadeOut(withDuration: 0.25)
        let scale = SKAction.scale(to: 0.3, duration: 0.25)
        let group = SKAction.group([move, fade, scale])
        particle.run(SKAction.sequence([group, .removeFromParent()]))
    }

    private func updateBackpackFlame() {
        guard let backpackFlame else { return }
        let offsetX = heroFacingRight ? -heroSize.width * 0.45 : heroSize.width * 0.45
        backpackFlame.position = CGPoint(x: offsetX, y: heroSize.height * 0.05)
        backpackFlame.xScale = heroFacingRight ? 1 : -1
        backpackFlame.isHidden = !(isJumpHeld || !isOnGround)
    }

    private func wrapLabel(_ label: SKLabelNode, maxWidth: CGFloat) {
        guard maxWidth > 0, let text = label.text else { return }
        let words = text.split(separator: " ")
        var lines: [String] = []
        var current = ""
        let font = UIFont(name: label.fontName ?? "Courier", size: label.fontSize) ?? UIFont.systemFont(ofSize: label.fontSize)
        for word in words {
            let tentative = current.isEmpty ? String(word) : current + " " + word
            let width = (tentative as NSString).size(withAttributes: [.font: font]).width
            if width > maxWidth && !current.isEmpty {
                lines.append(current)
                current = String(word)
            } else {
                current = tentative
            }
        }
        if !current.isEmpty { lines.append(current) }
        label.text = lines.joined(separator: "\n")
        label.numberOfLines = lines.count
    }

    private func lerp(_ value: CGFloat, target: CGFloat, t: CGFloat) -> CGFloat {
        value + (target - value) * max(0, min(1, t))
    }
}


