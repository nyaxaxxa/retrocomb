//
//  Level2Scene.swift
//  retrocomb
//
//  Space Flappy Game - Level 2 (Top-Down)
//

import SpriteKit
import UIKit

@MainActor
class Level2Scene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    private var player: Player!
    private var theme: ColorTheme = ColorTheme.classicGreen
    private var difficulty: GameConfig.Difficulty = .normal
    
    private var asteroids: [Asteroid] = []
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
    
    private var lastUpdateTime: TimeInterval = 0
    private var timeSinceLastSpawn: TimeInterval = 0
    
    // Upgrades
    private var coinsUntilUpgrade = GameConfig.Upgrade.coinCost
    private var isUpgradeMenuPresented = false
    private var currentUpgradeOptions: [GameConfig.UpgradeType] = []
    
    // Input
    private var moveLeft = false
    private var moveRight = false
    
    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        difficulty = GameData.shared.getCurrentDifficulty()
        isAIMode = (difficulty == .ai)
        
        setupScene()
        setupPlayer()
        setupUI()
        setupGestures()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        // Запускаем фоновую музыку
        SoundManager.shared.playBackgroundMusic(fileName: "retro_music.mp3")
    }
    
    private func setupScene() {
        backgroundColor = theme.skBackground
        
        // Create star field
        createStarField()
    }
    
    private func setupPlayer() {
        player = Player(level: 2, theme: theme)
        player.position = CGPoint(x: size.width / 2, y: 100)
        addChild(player)
    }
    
    private func setupUI() {
        let safeInsets = view?.safeAreaInsets ?? .zero
        let topY = size.height - safeInsets.top - DesignSystem.layoutVerticalPadding
        let leftX = safeInsets.left + DesignSystem.layoutHorizontalPadding
        let rightX = size.width - safeInsets.right - DesignSystem.layoutHorizontalPadding
        let centerX = size.width / 2 + (safeInsets.left - safeInsets.right) / 2
        
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(scoreLabel, style: .body, theme: theme, alignment: .left)
        scoreLabel.position = CGPoint(x: leftX, y: topY)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        updateScoreDisplay()
        
        coinsLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(coinsLabel, style: .body, theme: theme, alignment: .right)
        coinsLabel.fontColor = theme.skSecondary
        coinsLabel.position = CGPoint(x: rightX, y: topY)
        coinsLabel.zPosition = 100
        addChild(coinsLabel)
        updateCoinsDisplay()
        
        let levelLabel = SKLabelNode(fontNamed: "Courier")
        levelLabel.text = "УРОВЕНЬ 2"
        DesignSystem.apply(levelLabel, style: .subtitle, theme: theme)
        levelLabel.position = CGPoint(
            x: centerX,
            y: topY - (scoreLabel.frame.height + DesignSystem.layoutInterItemSpacing)
        )
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.zPosition = 100
        addChild(levelLabel)
        
        let diffLabel = SKLabelNode(fontNamed: "Courier")
        diffLabel.text = difficulty.name
        DesignSystem.apply(diffLabel, style: .footnote, theme: theme)
        diffLabel.fontColor = theme.skSecondary
        diffLabel.position = CGPoint(
            x: centerX,
            y: levelLabel.position.y - (levelLabel.frame.height + DesignSystem.layoutInterItemSpacing / 2)
        )
        diffLabel.horizontalAlignmentMode = .center
        diffLabel.zPosition = 100
        addChild(diffLabel)
        
        if !isAIMode {
            let hint = SKLabelNode(fontNamed: "Courier")
            hint.text = "СВАЙП ВЛЕВО/ВПРАВО — ДВИЖЕНИЕ"
            DesignSystem.apply(hint, style: .footnote, theme: theme)
            hint.fontColor = theme.skText.withAlphaComponent(0.65)
            hint.position = CGPoint(
                x: size.width / 2,
                y: safeInsets.bottom + DesignSystem.layoutVerticalPadding + 40
            )
            hint.zPosition = 100
            addChild(hint)
            
            let wait = SKAction.wait(forDuration: 3.0)
            let fade = SKAction.fadeOut(withDuration: 1.0)
            let remove = SKAction.removeFromParent()
            hint.run(SKAction.sequence([wait, fade, remove]))
        }
    }
    
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view?.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view?.addGestureRecognizer(swipeRight)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if isGameOver || isAIMode { return }
        
        if gesture.direction == .left {
            player.velocity.dx = -GameConfig.Level2.horizontalSpeed
        } else if gesture.direction == .right {
            player.velocity.dx = GameConfig.Level2.horizontalSpeed
        }
    }
    
    private func createStarField() {
        for _ in 0..<80 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let size = CGFloat.random(in: 1...2)
            
            let star = SKShapeNode(circleOfRadius: size)
            star.fillColor = theme.skPrimary.withAlphaComponent(0.3)
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: y)
            star.zPosition = -1
            addChild(star)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver || !player.isAlive {
            return
        }
        
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        timeSinceLastSpawn += deltaTime
        
        // AI mode
        if isAIMode {
            performAI()
        }
        
        // Apply friction
        player.velocity.dx *= GameConfig.Level2.friction
        player.updatePosition()
        
        // Bounds check
        if player.position.x < 50 {
            player.position.x = 50
            player.velocity.dx = 0
        } else if player.position.x > size.width - 50 {
            player.position.x = size.width - 50
            player.velocity.dx = 0
        }
        
        // Spawn asteroids
        let spawnRate = GameConfig.Level2.asteroidSpawnRate * difficulty.speedMultiplier
        if Double.random(in: 0...1) < spawnRate {
            spawnAsteroid()
        }
        
        // Spawn coins occasionally
        if timeSinceLastSpawn > 2.0 && Double.random(in: 0...1) < 0.3 {
            spawnCoin()
            timeSinceLastSpawn = 0
        }
        
        // Update asteroids
        for asteroid in asteroids {
            asteroid.position.y -= GameConfig.Level2.asteroidSpeed * difficulty.speedMultiplier
            
            // Check collision
            let distance = hypot(asteroid.position.x - player.position.x, asteroid.position.y - player.position.y)
            if distance < 40 {
                if player.hasShield {
                    player.removeShield()
                    asteroid.removeFromParent()
                    asteroids.removeAll { $0 == asteroid }
                } else {
                    gameOver()
                    return
                }
            }
            
            // Remove off-screen
            if asteroid.position.y < -100 {
                asteroid.removeFromParent()
                asteroids.removeAll { $0 == asteroid }
                score += 1
                
                // Check for level completion
                if score >= GameConfig.Level2.scoreToAdvance {
                    // Check if new record
                    let record = GameData.shared.level2Record
                    if record == 0 || score > record {
                        levelComplete()
                        return
                    }
                }
            }
        }
        
        // Update coins
        for coin in coins {
            coin.position.y -= GameConfig.Level2.asteroidSpeed * difficulty.speedMultiplier * 0.7
            
            // Magnet effect
            if player.magnetMultiplier > 1.0 {
                let distance = hypot(coin.position.x - player.position.x, coin.position.y - player.position.y)
                if distance < player.magnetRange && !coin.isCollected {
                    let dx = player.position.x - coin.position.x
                    let dy = player.position.y - coin.position.y
                    coin.position.x += dx * 0.1
                    coin.position.y += dy * 0.1
                }
            }
            
            // Check collection
            let distance = hypot(coin.position.x - player.position.x, coin.position.y - player.position.y)
            if distance < 30 && !coin.isCollected {
                collectCoin(coin)
            }
            
            // Remove off-screen
            if coin.position.y < -50 {
                coin.removeFromParent()
                coins.removeAll { $0 == coin }
            }
        }
        
        // Update particles
        let engineParticles = player.createEngineParticles()
        for particle in engineParticles {
            particles.append(particle)
            addChild(particle)
        }
        
        for particle in particles {
            particle.update(deltaTime: deltaTime)
            if particle.isDead {
                particle.removeFromParent()
            }
        }
        particles.removeAll { $0.isDead }
    }
    
    private func performAI() {
        // Find nearest asteroid
        var nearestAsteroid: Asteroid?
        var minDistance: CGFloat = .infinity
        
        for asteroid in asteroids {
            let distance = abs(asteroid.position.x - player.position.x)
            let yDistance = player.position.y - asteroid.position.y
            
            if yDistance > 0 && yDistance < 200 && distance < minDistance {
                minDistance = distance
                nearestAsteroid = asteroid
            }
        }
        
        // Move away from nearest asteroid
        if let asteroid = nearestAsteroid {
            if asteroid.position.x < player.position.x {
                // Asteroid is to the left, move right
                player.velocity.dx = GameConfig.Level2.horizontalSpeed * 0.8
            } else {
                // Asteroid is to the right, move left
                player.velocity.dx = -GameConfig.Level2.horizontalSpeed * 0.8
            }
        } else {
            // Move towards center
            let center = size.width / 2
            if player.position.x < center - 50 {
                player.velocity.dx = GameConfig.Level2.horizontalSpeed * 0.5
            } else if player.position.x > center + 50 {
                player.velocity.dx = -GameConfig.Level2.horizontalSpeed * 0.5
            }
        }
    }
    
    private func spawnAsteroid() {
        let x = CGFloat.random(in: 50...(size.width - 50))
        let asteroid = Asteroid(x: x, theme: theme)
        addChild(asteroid)
        asteroids.append(asteroid)
    }
    
    private func spawnCoin() {
        let x = CGFloat.random(in: 100...(size.width - 100))
        let coin = Coin(position: CGPoint(x: x, y: size.height + 50), theme: theme)
        addChild(coin)
        coins.append(coin)
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
        currentUpgradeOptions = Array(GameConfig.UpgradeType.allCases.shuffled().prefix(3))
        let availableCoins = GameData.shared.totalCoins
        let message = "Выбери улучшение для корабля.\nСтоимость: \(GameConfig.Upgrade.coinCost) монет.\n💎 В банке: \(availableCoins)"
        let buttons = currentUpgradeOptions.map { upgrade in
            OverlayButtonConfig(title: upgrade.description.uppercased(),
                                name: "upgrade_\(upgrade.rawValue)")
        }
        OverlayFactory.presentModal(on: self,
                                    scene: self,
                                    theme: theme,
                                    title: "МАГАЗИН МОДИФИКАЦИЙ",
                                    message: message,
                                    buttons: buttons,
                                    extraWidthMargin: 32,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let touchedNodes = nodes(at: touchLocation)
        
        if isUpgradeMenuPresented {
            for node in touchedNodes {
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
        
        for node in touchedNodes {
            guard let nodeName = node.name else { continue }
            
            if nodeName == "retry" {
                let nextSize = view?.bounds.size ?? size
                let scene = Level2Scene(size: nextSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            } else if nodeName == "menu" {
                let menuSize = view?.bounds.size ?? size
                let scene = MenuScene(size: menuSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            } else if nodeName == "next" {
                StoryManager.shared.presentPostLevelCutscene(from: self, level: 2, victory: true)
            } else if nodeName == "replay" {
                let scene = Level2Scene(size: size)
                scene.scaleMode = .aspectFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            }
        }
    }
    
    private func applyUpgrade(_ upgrade: GameConfig.UpgradeType) {
        switch upgrade {
        case .speed:
            player.speedMultiplier *= GameConfig.Upgrade.speedMultiplier
            
        case .size:
            player.sizeMultiplier *= GameConfig.Upgrade.sizeMultiplier
            player.setupForLevel(level: 2, theme: theme)
            
        case .shield:
            player.addShield(theme: theme)
            
        case .magnet:
            player.magnetMultiplier *= GameConfig.Upgrade.magnetMultiplier
        }
    }
    
    private func closeUpgradeMenu() {
        childNode(withName: "modal_dim")?.removeFromParent()
        childNode(withName: "modal_card")?.removeFromParent()
        currentUpgradeOptions.removeAll()
        isUpgradeMenuPresented = false
        isPaused = false
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Handled in update loop
    }
    
    // АНИМАЦИЯ ВЗРЫВА корабля
    private func explodePlayer() {
        // Звук взрыва
        SoundManager.shared.playSound(.explosion, on: self)
        
        // 1. Большой взрыв
        let explosion = ParticleEmitter.createExplosion(at: player.position, color: theme.skPrimary, count: 50)
        for particle in explosion {
            addChild(particle)
        }
        
        // 2. Раскалывание на части
        let shipSize = GameConfig.Level2.playerSize
        let pieces = 8
        
        for i in 0..<pieces {
            let angle = CGFloat(i) * (2 * .pi) / CGFloat(pieces)
            let pieceSize = CGSize(width: shipSize.width / 4, height: shipSize.height / 4)
            
            let piece = SKShapeNode(rectOf: pieceSize)
            piece.fillColor = theme.skPrimary
            piece.strokeColor = theme.skAccent
            piece.lineWidth = 2
            piece.glowWidth = 4
            piece.position = player.position
            piece.zRotation = angle
            piece.isAntialiased = false
            addChild(piece)
            
            // Разлетаются
            let velocity = CGVector(
                dx: cos(angle) * CGFloat.random(in: 10...20),
                dy: sin(angle) * CGFloat.random(in: 10...20)
            )
            
            let moveAction = SKAction.customAction(withDuration: 1.5) { node, time in
                node.position.x += velocity.dx
                node.position.y += velocity.dy
                node.zRotation += 0.3
                node.alpha = 1.0 - time / 1.5
            }
            
            let remove = SKAction.removeFromParent()
            piece.run(SKAction.sequence([moveAction, remove]))
        }
        
        // 3. Волновая вспышка
        for radius in stride(from: 30, through: 90, by: 20) {
            let ring = SKShapeNode(circleOfRadius: CGFloat(radius))
            ring.strokeColor = theme.skAccent
            ring.fillColor = .clear
            ring.lineWidth = 3
            ring.glowWidth = 5
            ring.position = player.position
            ring.alpha = 0
            addChild(ring)
            
            let delay = Double(radius - 30) / 60 * 0.2
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let expand = SKAction.scale(to: 2.0, duration: 0.4)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            
            ring.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([fadeIn, expand]),
                fadeOut,
                remove
            ]))
        }
        
        player.removeFromParent()
    }
    
    private func gameOver() {
        if isGameOver { return }
        isGameOver = true
        
        // Звук смерти
        SoundManager.shared.playSound(.die, on: self)
        
        explodePlayer()
        
        // Update records (НЕ в AI режиме!)
        GameData.shared.updateHighScore(score, isAIMode: isAIMode)
        GameData.shared.updateLevelRecord(level: 2, score: score, isAIMode: isAIMode)
        if !isAIMode {
            GameData.shared.totalCoins += totalCoins
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showGameOverScreen()
        }
    }
    
    private func levelComplete() {
        isGameOver = true
        
        // Update data (НЕ в AI режиме!)
        GameData.shared.updateHighScore(score, isAIMode: isAIMode)
        GameData.shared.updateLevelRecord(level: 2, score: score, isAIMode: isAIMode)
        if !isAIMode {
            GameData.shared.totalCoins += totalCoins
            GameData.shared.currentLevel = 3
        }
        
        showLevelCompleteScreen()
    }
    
    private func showGameOverScreen() {
        let buttons = [
            OverlayButtonConfig(title: "↻ ЗАНОВО", name: "retry"),
            OverlayButtonConfig(title: "◄ МЕНЮ", name: "menu")
        ]
        OverlayFactory.presentModal(on: self,
                                    scene: self,
                                    theme: theme,
                                    message: StoryManager.shared.randomPostmortem(),
                                    buttons: buttons,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }
    
    private func showLevelCompleteScreen() {
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = .black
        overlay.alpha = 0.8
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 300
        addChild(overlay)
        
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "УРОВЕНЬ ПРОЙДЕН!"
        title.fontSize = 50
        title.fontColor = theme.skPrimary
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        title.zPosition = 301
        addChild(title)
        
        let recap = SKLabelNode(fontNamed: "Courier")
        recap.text = "Сканеры фиксируют мусорщиков. Остаться или прорываться?"
        recap.fontSize = 22
        recap.fontColor = theme.skSecondary
        recap.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        recap.zPosition = 301
        addChild(recap)
        recap.preferredMaxLayoutWidth = safeContentWidth(margin: 80)
        wrapLabel(recap, maxWidth: recap.preferredMaxLayoutWidth)
        
        createGameOverButton(text: "↻ Продолжить (рекорд)", position: CGPoint(x: size.width / 2, y: size.height / 2 - 60), name: "replay")
        createGameOverButton(text: "► Следующий этап", position: CGPoint(x: size.width / 2, y: size.height / 2 - 140), name: "next")
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
        addChild(button)
        
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        DesignSystem.apply(label, style: .button, theme: theme)
        label.position = CGPoint(x: 0, y: 0)
        label.preferredMaxLayoutWidth = DesignSystem.buttonSize.width - DesignSystem.buttonContentInset * 2
        button.addChild(label)
        
        return button
    }

    private func wrapLabel(_ label: SKLabelNode, maxWidth: CGFloat) {
        guard let originalText = label.text else { return }
        let words = originalText.split(separator: " ")
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
}
