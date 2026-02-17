//
//  Level3Scene.swift
//  retrocomb
//
//  Space Flappy Game - Level 3 (Open World)
//

import SpriteKit
import UIKit

@MainActor
class Level3Scene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    private var player: Player!
    private var theme: ColorTheme = ColorTheme.classicGreen
    private var difficulty: GameConfig.Difficulty = .normal
    
    private var enemies: [Enemy] = []
    private var foods: [Food] = []
    private var coins: [Coin] = []
    private var particles: [Particle] = []
    
    private var score: Int = 0 {
        didSet {
            guard oldValue != score else { return }
            updateScoreDisplay()
        }
    }
    private var totalCoins: Int = 0 {
        didSet {
            guard oldValue != totalCoins else { return }
            updateCoinsDisplay()
        }
    }
    private var isGameOver = false
    private var isAIMode = false
    
    private var scoreLabel: SKLabelNode!
    private var coinsLabel: SKLabelNode!
    private var sizeLabel: SKLabelNode!
    
    private var lastUpdateTime: TimeInterval = 0
    
    // World and camera
    private let worldWidth = GameConfig.Level3.worldWidth
    private let worldHeight = GameConfig.Level3.worldHeight
    private var worldNode: SKNode!
    private var cameraNode: SKCameraNode!
    
    // Minimap
    private var minimapNode: SKShapeNode!
    private var minimapPlayerDot: SKShapeNode!
    
    // Upgrades
    private var coinsUntilUpgrade = GameConfig.Upgrade.coinCost
    private var isUpgradeMenuPresented = false
    private var currentUpgradeOptions: [GameConfig.UpgradeType] = []
    
    // Input
    private var moveDirection = CGVector.zero
    private var touchLocation: CGPoint?
    
    private var messageLabel: SKLabelNode?
    private var hasTriggeredVictory = false
    
    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        difficulty = GameData.shared.getCurrentDifficulty()
        isAIMode = (difficulty == .ai)
        
        setupWorld()
        setupCamera()
        setupPlayer()
        setupEnemies()
        setupFood()
        setupUI()
        setupMinimap()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        // Запускаем фоновую музыку
        SoundManager.shared.playBackgroundMusic(fileName: "retro_music.mp3")
    }
    
    private func setupWorld() {
        // Create world container
        worldNode = SKNode()
        worldNode.name = "world"
        addChild(worldNode)
        
        // Background color
        backgroundColor = theme.skBackground
        
        // Create star field
        for _ in 0..<200 {
            let x = CGFloat.random(in: 0...worldWidth)
            let y = CGFloat.random(in: 0...worldHeight)
            let size = CGFloat.random(in: 1...3)
            
            let star = SKShapeNode(circleOfRadius: size)
            star.fillColor = theme.skPrimary.withAlphaComponent(CGFloat.random(in: 0.2...0.5))
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            star.zPosition = -1
            worldNode.addChild(star)
        }
        
        // Create grid
        createWorldGrid()
    }
    
    private func createWorldGrid() {
        let gridSpacing: CGFloat = 100
        
        // Vertical lines
        for x in stride(from: 0, through: worldWidth, by: gridSpacing) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: worldHeight))
            line.path = path
            line.strokeColor = theme.skPrimary.withAlphaComponent(0.1)
            line.lineWidth = 1
            line.zPosition = -2
            worldNode.addChild(line)
        }
        
        // Horizontal lines
        for y in stride(from: 0, through: worldHeight, by: gridSpacing) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: worldWidth, y: y))
            line.path = path
            line.strokeColor = theme.skPrimary.withAlphaComponent(0.1)
            line.lineWidth = 1
            line.zPosition = -2
            worldNode.addChild(line)
        }
        
        // World borders
        let border = SKShapeNode(rectOf: CGSize(width: worldWidth, height: worldHeight))
        border.position = CGPoint(x: worldWidth / 2, y: worldHeight / 2)
        border.strokeColor = theme.skPrimary
        border.lineWidth = 4
        border.glowWidth = 4
        border.fillColor = .clear
        border.zPosition = 10
        worldNode.addChild(border)
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)
    }
    
    private func setupPlayer() {
        player = Player(level: 3, theme: theme)
        player.position = CGPoint(x: worldWidth / 2, y: worldHeight / 2)
        worldNode.addChild(player)
    }
    
    private func setupEnemies() {
        for _ in 0..<GameConfig.Level3.enemyCount {
            let x = CGFloat.random(in: 200...(worldWidth - 200))
            let y = CGFloat.random(in: 200...(worldHeight - 200))
            
            // Более разнообразные размеры врагов
            let size: CGFloat
            let rand = Int.random(in: 0...100)
            if rand < 30 {
                // 30% - маленькие враги (10-15)
                size = CGFloat.random(in: 10...15)
            } else if rand < 70 {
                // 40% - средние враги (15-30)
                size = CGFloat.random(in: 15...30)
            } else if rand < 90 {
                // 20% - большие враги (30-50) - ОПАСНЫЕ!
                size = CGFloat.random(in: 30...50)
            } else {
                // 10% - ОГРОМНЫЕ боссы (50-80) - ОЧЕНЬ ОПАСНЫЕ!
                size = CGFloat.random(in: 50...80)
            }
            
            let enemy = Enemy(position: CGPoint(x: x, y: y), size: size, theme: theme)
            worldNode.addChild(enemy)
            enemies.append(enemy)
        }
    }
    
    private func setupFood() {
        for _ in 0..<GameConfig.Level3.foodCount {
            let x = CGFloat.random(in: 50...(worldWidth - 50))
            let y = CGFloat.random(in: 50...(worldHeight - 50))
            
            let food = Food(position: CGPoint(x: x, y: y), theme: theme)
            worldNode.addChild(food)
            foods.append(food)
        }
        
        // Spawn coins - больше в большом мире
        for _ in 0..<150 {  // Увеличено с 30 до 150
            let x = CGFloat.random(in: 200...(worldWidth - 200))
            let y = CGFloat.random(in: 200...(worldHeight - 200))
            
            let coin = Coin(position: CGPoint(x: x, y: y), theme: theme)
            worldNode.addChild(coin)
            coins.append(coin)
        }
    }
    
    private func setupUI() {
        let safeInsets = view?.safeAreaInsets ?? .zero
        let topY = size.height / 2 - safeInsets.top - DesignSystem.layoutVerticalPadding
        let leftX = -size.width / 2 + safeInsets.left + DesignSystem.layoutHorizontalPadding
        let rightX = size.width / 2 - safeInsets.right - DesignSystem.layoutHorizontalPadding
        let centerX = (safeInsets.left - safeInsets.right) / 2
        
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(scoreLabel, style: .body, theme: theme, alignment: .left)
        scoreLabel.position = CGPoint(x: leftX, y: topY)
        scoreLabel.zPosition = 100
        cameraNode.addChild(scoreLabel)
        updateScoreDisplay()
        
        coinsLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(coinsLabel, style: .body, theme: theme, alignment: .right)
        coinsLabel.fontColor = theme.skSecondary
        coinsLabel.position = CGPoint(x: rightX, y: topY)
        coinsLabel.zPosition = 100
        cameraNode.addChild(coinsLabel)
        updateCoinsDisplay()
        
        sizeLabel = SKLabelNode(fontNamed: "Courier")
        sizeLabel.text = "Размер: 1.0x"
        DesignSystem.apply(sizeLabel, style: .subtitle, theme: theme)
        sizeLabel.position = CGPoint(
            x: centerX,
            y: topY - (scoreLabel.frame.height + DesignSystem.layoutInterItemSpacing)
        )
        sizeLabel.horizontalAlignmentMode = .center
        sizeLabel.zPosition = 100
        cameraNode.addChild(sizeLabel)
        fitCenteredHUDLabel(sizeLabel)
        
        let levelLabel = SKLabelNode(fontNamed: "Courier-Bold")
        levelLabel.text = "⚠️ УРОВЕНЬ 3 — EXTREME SURVIVAL ⚠️"
        DesignSystem.apply(levelLabel, style: .footnote, theme: theme)
        levelLabel.fontColor = theme.skAccent
        levelLabel.position = CGPoint(
            x: centerX,
            y: sizeLabel.position.y - (sizeLabel.frame.height + DesignSystem.layoutInterItemSpacing / 2)
        )
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.zPosition = 100
        cameraNode.addChild(levelLabel)
        
        let warning = SKLabelNode(fontNamed: "Courier")
        warning.text = "100 ВРАГОВ • МИР 15000×20000"
        DesignSystem.apply(warning, style: .footnote, theme: theme)
        warning.fontColor = theme.skPrimary
        warning.position = CGPoint(
            x: centerX,
            y: levelLabel.position.y - (levelLabel.frame.height + DesignSystem.layoutInterItemSpacing / 2)
        )
        warning.horizontalAlignmentMode = .center
        warning.zPosition = 100
        cameraNode.addChild(warning)
        
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        warning.run(SKAction.repeatForever(flash))
    }
    
    private func setupMinimap() {
        let minimapSize = GameConfig.Level3.minimapSize
        let minimapHeight = minimapSize * 1.33
        
        // Компактная миникарта в правом нижнем углу
        minimapNode = SKShapeNode(rectOf: CGSize(width: minimapSize, height: minimapHeight))
        minimapNode.fillColor = theme.skBackground.withAlphaComponent(0.88)
        minimapNode.strokeColor = theme.skPrimary
        minimapNode.lineWidth = 2
        minimapNode.glowWidth = 2
        minimapNode.alpha = 0.92
        minimapNode.isAntialiased = false
        // Учитываем безопасные зоны устройства
        let safeInsets = view?.safeAreaInsets ?? .zero
        minimapNode.position = CGPoint(
            x: size.width / 2 - minimapSize / 2 - 15 - safeInsets.right,
            y: -size.height / 2 + minimapHeight / 2 + 15 + safeInsets.bottom
        )
        minimapNode.zPosition = 98
        cameraNode.addChild(minimapNode)
        
        // Рамка границ мира
        let worldBorder = SKShapeNode(rectOf: CGSize(width: minimapSize - 8, height: minimapHeight - 8))
        worldBorder.fillColor = .clear
        worldBorder.strokeColor = theme.skAccent.withAlphaComponent(0.4)
        worldBorder.lineWidth = 1
        worldBorder.isAntialiased = false
        worldBorder.zPosition = 1
        minimapNode.addChild(worldBorder)
        
        // Точка игрока - яркая и крупная
        minimapPlayerDot = SKShapeNode(rectOf: CGSize(width: 5, height: 5))
        minimapPlayerDot.fillColor = theme.skAccent
        minimapPlayerDot.strokeColor = .white
        minimapPlayerDot.lineWidth = 1
        minimapPlayerDot.glowWidth = 4
        minimapPlayerDot.isAntialiased = false
        minimapPlayerDot.zPosition = 100
        minimapPlayerDot.position = .zero
        minimapNode.addChild(minimapPlayerDot)
        
        // Пульсация для видимости
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])
        minimapPlayerDot.run(SKAction.repeatForever(pulse))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver { return }
        
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver { return }
        
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = nil
        
        guard let touch = touches.first else { return }
        let sceneTouchLocation = touch.location(in: self)
        let sceneTouchedNodes = nodes(at: sceneTouchLocation)
        
        if isUpgradeMenuPresented {
            for node in sceneTouchedNodes {
                guard let nodeName = node.name else { continue }
                if nodeName.hasPrefix("upgrade_") {
                    let upgradeName = nodeName.replacingOccurrences(of: "upgrade_", with: "")
                    guard let upgrade = GameConfig.UpgradeType(rawValue: upgradeName),
                          currentUpgradeOptions.contains(upgrade) else { continue }
                    applyUpgrade(upgrade)
                    closeUpgradeMenu()
                    break
                }
            }
            return
        }
        
        // Check for UI buttons
        let cameraLocation = touch.location(in: cameraNode)
        let uiTouchedNodes = cameraNode.nodes(at: cameraLocation)
        
        for node in uiTouchedNodes {
            guard let nodeName = node.name else { continue }
            
            if nodeName == "retry" {
                let nextSize = view?.bounds.size ?? size
                let scene = Level3Scene(size: nextSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            } else if nodeName == "menu" {
                let menuSize = view?.bounds.size ?? size
                let scene = MenuScene(size: menuSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            } else if nodeName == "next" {
                StoryManager.shared.presentPostLevelCutscene(from: self, level: 3, victory: true)
            } else if nodeName == "replay" {
                let scene = Level3Scene(size: size)
                scene.scaleMode = .aspectFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver || !player.isAlive {
            return
        }
        
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Handle input
        if !isAIMode {
            handlePlayerInput()
        } else {
            performAI()
        }
        
        // Apply acceleration and friction
        player.velocity.dx += moveDirection.dx * GameConfig.Level3.acceleration
        player.velocity.dy += moveDirection.dy * GameConfig.Level3.acceleration
        
        // Apply friction
        player.velocity.dx *= GameConfig.Level3.friction
        player.velocity.dy *= GameConfig.Level3.friction
        
        // Limit max speed
        let speed = sqrt(player.velocity.dx * player.velocity.dx + player.velocity.dy * player.velocity.dy)
        if speed > GameConfig.Level3.maxSpeed {
            let scale = GameConfig.Level3.maxSpeed / speed
            player.velocity.dx *= scale
            player.velocity.dy *= scale
        }
        
        // Update player
        player.updatePosition()
        player.updateRotation()
        
        // Bounds check
        if player.position.x < 0 {
            player.position.x = 0
            player.velocity.dx = 0
        } else if player.position.x > worldWidth {
            player.position.x = worldWidth
            player.velocity.dx = 0
        }
        
        if player.position.y < 0 {
            player.position.y = 0
            player.velocity.dy = 0
        } else if player.position.y > worldHeight {
            player.position.y = worldHeight
            player.velocity.dy = 0
        }
        
        // Update camera
        updateCamera()
        
        // Update enemies
        for enemy in enemies where enemy.isAlive {
            enemy.updateAI(playerPosition: player.position, worldBounds: CGSize(width: worldWidth, height: worldHeight))
            enemy.updatePosition()
            
            // Bounds check
            if enemy.position.x < 0 { enemy.position.x = 0; enemy.velocity.dx *= -1 }
            if enemy.position.x > worldWidth { enemy.position.x = worldWidth; enemy.velocity.dx *= -1 }
            if enemy.position.y < 0 { enemy.position.y = 0; enemy.velocity.dy *= -1 }
            if enemy.position.y > worldHeight { enemy.position.y = worldHeight; enemy.velocity.dy *= -1 }
            
            // Check collision with player - УЛУЧШЕННАЯ ЛОГИКА
            let distance = hypot(enemy.position.x - player.position.x, enemy.position.y - player.position.y)
            let collisionDistance = enemy.size + (player.sizeMultiplier * 25)
            
            if distance < collisionDistance {
                let playerEffectiveSize = player.sizeMultiplier * 30
                let sizeDifference = enemy.size - playerEffectiveSize
                
                // Враг больше на 20% или более - игрок погибает!
                if sizeDifference > playerEffectiveSize * 0.2 {
                    // Enemy is bigger - player dies or loses shield
                    if player.hasShield {
                        player.removeShield()
                        // Отталкиваем игрока при ударе в щит
                        let knockbackAngle = atan2(player.position.y - enemy.position.y, 
                                                   player.position.x - enemy.position.x)
                        player.velocity.dx += cos(knockbackAngle) * 5
                        player.velocity.dy += sin(knockbackAngle) * 5
                    } else {
                        gameOver()
                        return
                    }
                } else if sizeDifference < -playerEffectiveSize * 0.2 {
                    // Player is significantly bigger - eat enemy
                    SoundManager.shared.playSound(.enemyDie, on: self)
                    enemy.die(theme: theme)
                    player.grow(amount: 0.05)
                    score += Int(enemy.size * 2)  // Больше очков
                    sizeLabel.text = String(format: "Размер: %.1fx", player.sizeMultiplier)
                    fitCenteredHUDLabel(sizeLabel)
                    fitCenteredHUDLabel(sizeLabel)
                } else {
                    // Примерно одинаковые - оба отталкиваются
                    let angle = atan2(player.position.y - enemy.position.y, 
                                     player.position.x - enemy.position.x)
                    player.velocity.dx += cos(angle) * 3
                    player.velocity.dy += sin(angle) * 3
                    enemy.velocity.dx -= cos(angle) * 3
                    enemy.velocity.dy -= sin(angle) * 3
                }
            }
        }
        
        // Remove dead enemies
        enemies.removeAll { !$0.isAlive }
        
        // Enemy merging
        for i in 0..<enemies.count {
            for j in (i+1)..<enemies.count {
                let enemy1 = enemies[i]
                let enemy2 = enemies[j]
                let distance = hypot(enemy1.position.x - enemy2.position.x, enemy1.position.y - enemy2.position.y)
                
                if distance < (enemy1.size + enemy2.size) / 2 {
                    // Merge smaller into larger
                    if enemy1.size >= enemy2.size {
                        enemy1.grow(amount: enemy2.size * 0.5)
                        SoundManager.shared.playSound(.enemyDie, on: self)
                        enemy2.die(theme: theme)
                    } else {
                        enemy2.grow(amount: enemy1.size * 0.5)
                        SoundManager.shared.playSound(.enemyDie, on: self)
                        enemy1.die(theme: theme)
                    }
                }
            }
        }
        
        // Update food
        for food in foods where !food.isEaten {
            let distance = hypot(food.position.x - player.position.x, food.position.y - player.position.y)
            if distance < 30 {
                food.eat()
                player.grow(amount: 0.02)
                sizeLabel.text = String(format: "Размер: %.1fx", player.sizeMultiplier)
                fitCenteredHUDLabel(sizeLabel)
            }
        }
        foods.removeAll { $0.isEaten }
        
        // Update coins
        for coin in coins where !coin.isCollected {
            // Magnet effect
            if player.magnetMultiplier > 1.0 {
                let distance = hypot(coin.position.x - player.position.x, coin.position.y - player.position.y)
                if distance < player.magnetRange {
                    let dx = player.position.x - coin.position.x
                    let dy = player.position.y - coin.position.y
                    coin.position.x += dx * 0.1
                    coin.position.y += dy * 0.1
                }
            }
            
            // Check collection
            let distance = hypot(coin.position.x - player.position.x, coin.position.y - player.position.y)
            if distance < 30 {
                collectCoin(coin)
            }
        }
        coins.removeAll { $0.isCollected }
        
        // Update particles
        let engineParticles = player.createEngineParticles()
        for particle in engineParticles {
            particles.append(particle)
            worldNode.addChild(particle)
        }
        
        for particle in particles {
            particle.update(deltaTime: deltaTime)
            if particle.isDead {
                particle.removeFromParent()
            }
        }
        particles.removeAll { $0.isDead }
        
        // Update minimap
        updateMinimap()
        checkVictoryCondition()
        
        // Spawn more food if needed - больше еды в огромном мире
        if foods.count < 100 && Double.random(in: 0...1) < 0.05 {
            let x = CGFloat.random(in: 200...(worldWidth - 200))
            let y = CGFloat.random(in: 200...(worldHeight - 200))
            let food = Food(position: CGPoint(x: x, y: y), theme: theme)
            worldNode.addChild(food)
            foods.append(food)
        }
    }
    
    private func handlePlayerInput() {
        guard let location = touchLocation else {
            moveDirection = .zero
            return
        }
        
        // Convert touch location from scene to world coordinates
        let worldLocation = worldNode.convert(location, from: self)
        let dx = worldLocation.x - player.position.x
        let dy = worldLocation.y - player.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance > 30 {
            moveDirection = CGVector(dx: dx / distance, dy: dy / distance)
        } else {
            moveDirection = .zero
        }
    }
    
    private func performAI() {
        // Find nearest food or coin
        var nearestTarget: CGPoint?
        var minDistance: CGFloat = .infinity
        
        for food in foods where !food.isEaten {
            let distance = hypot(food.position.x - player.position.x, food.position.y - player.position.y)
            if distance < minDistance {
                minDistance = distance
                nearestTarget = food.position
            }
        }
        
        for coin in coins where !coin.isCollected {
            let distance = hypot(coin.position.x - player.position.x, coin.position.y - player.position.y)
            if distance < minDistance {
                minDistance = distance
                nearestTarget = coin.position
            }
        }
        
        // Find nearest dangerous enemy
        for enemy in enemies where enemy.isAlive {
            if enemy.size > player.sizeMultiplier * 30 {
                let distance = hypot(enemy.position.x - player.position.x, enemy.position.y - player.position.y)
                if distance < 150 {
                    // Run away from danger
                    let dx = player.position.x - enemy.position.x
                    let dy = player.position.y - enemy.position.y
                    let dist = sqrt(dx * dx + dy * dy)
                    moveDirection = CGVector(dx: dx / dist, dy: dy / dist)
                    return
                }
            }
        }
        
        // Move towards target
        if let target = nearestTarget {
            let dx = target.x - player.position.x
            let dy = target.y - player.position.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance > 0 {
                moveDirection = CGVector(dx: dx / distance, dy: dy / distance)
            }
        }
    }
    
    private func updateCamera() {
        // Center camera on player
        cameraNode.position = player.position
        
        // Keep camera within world bounds
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        if cameraNode.position.x < halfWidth {
            cameraNode.position.x = halfWidth
        } else if cameraNode.position.x > worldWidth - halfWidth {
            cameraNode.position.x = worldWidth - halfWidth
        }
        
        if cameraNode.position.y < halfHeight {
            cameraNode.position.y = halfHeight
        } else if cameraNode.position.y > worldHeight - halfHeight {
            cameraNode.position.y = worldHeight - halfHeight
        }
    }
    
    private func updateMinimap() {
        let minimapSize = GameConfig.Level3.minimapSize
        let minimapHeight = minimapSize * 1.33
        
        // Относительная позиция игрока на миникарте (от -1 до 1)
        let normalizedX = (player.position.x / worldWidth - 0.5) * 2
        let normalizedY = (player.position.y / worldHeight - 0.5) * 2
        
        // Позиция точки относительно центра миникарты
        let dotX = normalizedX * (minimapSize / 2 - 4)
        let dotY = normalizedY * (minimapHeight / 2 - 4)
        
        // Позиция точки внутри миникарты
        minimapPlayerDot.position = CGPoint(x: dotX, y: dotY)
    }
    
    private func collectCoin(_ coin: Coin) {
        coin.collect()
        totalCoins += 1
        SoundManager.shared.playSound(.coinCollect, on: self)
        
        // Check for upgrade
        coinsUntilUpgrade -= 1
        if coinsUntilUpgrade <= 0 {
            showUpgradeMenu()
            coinsUntilUpgrade = GameConfig.Upgrade.coinCost
        }
    }
    
    private func showUpgradeMenu() {
        guard !isUpgradeMenuPresented else { return }
        isUpgradeMenuPresented = true
        isPaused = true
        cameraNode.isPaused = true
        currentUpgradeOptions = Array(GameConfig.UpgradeType.allCases.shuffled().prefix(3))
        let availableCoins = GameData.shared.totalCoins
        let message = "Выбери усиление экипировки.\nСтоимость: \(GameConfig.Upgrade.coinCost) монет.\n💎 В банке: \(availableCoins)"
        let buttons = currentUpgradeOptions.map { upgrade in
            OverlayButtonConfig(title: upgrade.description.uppercased(),
                                name: "upgrade_\(upgrade.rawValue)")
        }
        OverlayFactory.presentModal(on: self,
                                    scene: self,
                                    theme: theme,
                                    title: "ЦЕНТР МОДЕРНИЗАЦИИ",
                                    message: message,
                                    buttons: buttons,
                                    extraWidthMargin: 32,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }
    
    private func createUpgradeButton(upgrade: GameConfig.UpgradeType, position: CGPoint) {
        let button = SKShapeNode(rectOf: CGSize(width: 400, height: 60), cornerRadius: 5)
        button.fillColor = .clear
        button.strokeColor = theme.skPrimary
        button.lineWidth = 3
        button.glowWidth = 3
        button.position = position
        button.zPosition = 201
        button.name = "upgrade_\(upgrade.rawValue)"
        cameraNode.addChild(button)
        
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = upgrade.rawValue
        label.fontSize = 24
        label.fontColor = theme.skPrimary
        label.position = CGPoint(x: 0, y: -8)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        button.addChild(label)
    }
    
    private func applyUpgrade(_ upgrade: GameConfig.UpgradeType) {
        switch upgrade {
        case .speed:
            player.speedMultiplier *= GameConfig.Upgrade.speedMultiplier
            
        case .size:
            player.sizeMultiplier *= GameConfig.Upgrade.sizeMultiplier
            player.setupForLevel(level: 3, theme: theme)
            
        case .shield:
            player.addShield(theme: theme)
            
        case .magnet:
            player.magnetMultiplier *= GameConfig.Upgrade.magnetMultiplier
        }
    }
    
    private func closeUpgradeMenu() {
        cameraNode.childNode(withName: "modal_dim")?.removeFromParent()
        cameraNode.childNode(withName: "modal_card")?.removeFromParent()
        currentUpgradeOptions.removeAll()
        isUpgradeMenuPresented = false
        isPaused = false
        cameraNode.isPaused = false
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Handled in update loop
    }
    
    private func gameOver() {
        if isGameOver { return }
        isGameOver = true
        
        // Звук смерти и взрыва
        SoundManager.shared.playSound(.die, on: self)
        SoundManager.shared.playSound(.explosion, on: self)
        
        player.die()
        
        // Update records (НЕ в AI режиме!)
        GameData.shared.updateHighScore(score, isAIMode: isAIMode)
        GameData.shared.updateLevelRecord(level: 3, score: score, isAIMode: isAIMode)
        if !isAIMode {
            GameData.shared.totalCoins += totalCoins
            
            // Проверка перехода на уровень 4
            let record = GameData.shared.level3Record
            if score >= GameConfig.Level3.scoreToAdvance && score >= record {
                GameData.shared.currentLevel = 4
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showGameOverScreen()
        }
    }
    
    private func showGameOverScreen() {
        let buttons = [
            OverlayButtonConfig(title: "↻ ЗАНОВО", name: "retry"),
            OverlayButtonConfig(title: "◄ МЕНЮ", name: "menu")
        ]
        OverlayFactory.presentModal(on: cameraNode,
                                    scene: self,
                                    theme: theme,
                                    message: StoryManager.shared.randomPostmortem(),
                                    buttons: buttons,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }
    
    @discardableResult
    private func createGameOverButton(text: String, position: CGPoint, name: String) -> SKShapeNode {
        let button = SKShapeNode(rectOf: DesignSystem.buttonSize, cornerRadius: DesignSystem.cardCornerRadius)
        button.fillColor = .clear
        button.strokeColor = theme.skPrimary
        button.lineWidth = 3
        button.glowWidth = 3
        button.position = position
        button.zPosition = 301
        button.name = name
        button.isAntialiased = false
        cameraNode.addChild(button)
        
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        DesignSystem.apply(label, style: .button, theme: theme)
        label.position = CGPoint(x: 0, y: 0)
        label.preferredMaxLayoutWidth = DesignSystem.buttonSize.width - DesignSystem.buttonContentInset * 2
        button.addChild(label)
        
        return button
    }

    private func completeStage() {
        guard !isGameOver else { return }
        isGameOver = true
        hasTriggeredVictory = true
        GameData.shared.updateHighScore(score, isAIMode: isAIMode)
        GameData.shared.updateLevelRecord(level: 3, score: score, isAIMode: isAIMode)
        if !isAIMode {
            GameData.shared.totalCoins += totalCoins
            GameData.shared.currentLevel = 4
        }
        showVictoryOverlay()
    }
    
    private func showVictoryOverlay() {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = .black
        overlay.alpha = 0.78
        overlay.position = .zero
        overlay.zPosition = 300
        cameraNode.addChild(overlay)
        
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "ОЧИЩЕНО!"
        title.fontSize = 48
        title.fontColor = theme.skPrimary
        title.position = CGPoint(x: 0, y: 140)
        title.zPosition = 301
        cameraNode.addChild(title)
        
        let recap = SKLabelNode(fontNamed: "Courier")
        recap.text = "Свобода от мусорщиков. Остаться для рекорда?"
        recap.fontSize = 22
        recap.fontColor = theme.skSecondary
        recap.position = CGPoint(x: 0, y: 70)
        recap.zPosition = 301
        recap.preferredMaxLayoutWidth = safeContentWidth(margin: 120)
        wrapLabel(recap, maxWidth: recap.preferredMaxLayoutWidth)
        
        createGameOverButton(text: "↻ Продолжить (рекорд)", position: CGPoint(x: 0, y: -40), name: "replay")
        createGameOverButton(text: "► Следующий этап", position: CGPoint(x: 0, y: -120), name: "next")
    }
    
    private func checkVictoryCondition() {
        guard !isGameOver, !hasTriggeredVictory else { return }
        if score >= GameConfig.Level3.scoreToAdvance {
            completeStage()
        }
    }
    
    private func wrapLabel(_ label: SKLabelNode, maxWidth: CGFloat) {
        guard let text = label.text else { return }
        let words = text.split(separator: " ")
        var current = ""
        var lines: [String] = []
        let font = UIFont(name: label.fontName ?? "Courier", size: label.fontSize) ?? UIFont.systemFont(ofSize: label.fontSize)
        for word in words {
            let tentative = current.isEmpty ? String(word) : current + " " + word
            let tentativeWidth = (tentative as NSString).size(withAttributes: [.font: font]).width
            if tentativeWidth > maxWidth && !current.isEmpty {
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
    
    private func safeContentWidth(margin: CGFloat) -> CGFloat {
        return DesignSystem.readableContentWidth(for: self, extraMargin: margin)
    }
    
    private func updateScoreDisplay() {
        guard let scoreLabel = scoreLabel else { return }
        scoreLabel.text = "СЧЁТ: \(score)"
        let safeInsets = view?.safeAreaInsets ?? .zero
        let safeWidth = size.width - safeInsets.left - safeInsets.right - DesignSystem.layoutHorizontalPadding * 2
        let maxWidth = max(160, safeWidth * 0.48)
        scoreLabel.preferredMaxLayoutWidth = maxWidth
        DesignSystem.fit(scoreLabel, maxWidth: maxWidth)
    }
    
    private func updateCoinsDisplay() {
        guard let coinsLabel = coinsLabel else { return }
        coinsLabel.text = "💎 \(totalCoins)"
        let safeInsets = view?.safeAreaInsets ?? .zero
        let safeWidth = size.width - safeInsets.left - safeInsets.right - DesignSystem.layoutHorizontalPadding * 2
        let maxWidth = max(160, safeWidth * 0.48)
        coinsLabel.preferredMaxLayoutWidth = maxWidth
        DesignSystem.fit(coinsLabel, maxWidth: maxWidth)
    }
    
    private func fitCenteredHUDLabel(_ label: SKLabelNode) {
        let maxWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 40)
        DesignSystem.fit(label, maxWidth: maxWidth)
    }
}
