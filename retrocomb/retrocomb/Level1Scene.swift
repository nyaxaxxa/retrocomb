//
//  Level1Scene.swift
//  retrocomb
//
//  Space Flappy Game - Level 1 (Flappy Bird style)
//

import SpriteKit
import UIKit

@MainActor
class Level1Scene: SKScene, @preconcurrency SKPhysicsContactDelegate {
    private var player: Player!
    private var theme: ColorTheme = ColorTheme.classicGreen
    private var difficulty: GameConfig.Difficulty = .normal
    
    private var pipes: [Pipe] = []
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
    
    private var lastPipeX: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0
    private var lastAIJumpTime: TimeInterval = 0  // Таймер для AI прыжков
    
    // Upgrades
    private var coinsUntilUpgrade = GameConfig.Upgrade.coinCost
    private var isUpgradeMenuPresented = false
    private var currentUpgradeOptions: [GameConfig.UpgradeType] = []
    
    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        difficulty = GameData.shared.getCurrentDifficulty()
        isAIMode = (difficulty == .ai)
        
        setupScene()
        setupPlayer()
        setupUI()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
        // Запускаем фоновую музыку
        SoundManager.shared.playBackgroundMusic(fileName: "retro_music.mp3")
    }
    
    private func setupScene() {
        backgroundColor = theme.skBackground
        
        // Create star field
        createStarField()
        
        // Initial pipes
        lastPipeX = size.width
        for i in 0..<3 {
            spawnPipe(at: lastPipeX + GameConfig.Level1.pipeSpacing * CGFloat(i + 1))
        }
    }
    
    private func setupPlayer() {
        player = Player(level: 1, theme: theme)
        // Начинаем слева, в середине по вертикали
        player.position = CGPoint(x: 150, y: size.height / 2)
        player.velocity.dy = 0 // Начинаем без движения
        addChild(player)
    }
    
    private func setupUI() {
        let safeInsets = view?.safeAreaInsets ?? .zero
        let topY = size.height - safeInsets.top - DesignSystem.layoutVerticalPadding
        let leftX = safeInsets.left + DesignSystem.layoutHorizontalPadding
        let rightX = size.width - safeInsets.right - DesignSystem.layoutHorizontalPadding
        let centerX = size.width / 2 + (safeInsets.left - safeInsets.right) / 2
        
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(scoreLabel, style: .body, theme: theme, alignment: .left)
        scoreLabel.position = CGPoint(x: leftX, y: topY)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        updateScoreDisplay()
        
        // Coins label
        coinsLabel = SKLabelNode(fontNamed: "Courier-Bold")
        DesignSystem.apply(coinsLabel, style: .body, theme: theme, alignment: .right)
        coinsLabel.fontColor = theme.skSecondary
        coinsLabel.position = CGPoint(x: rightX, y: topY)
        coinsLabel.zPosition = 100
        addChild(coinsLabel)
        updateCoinsDisplay()
        
        // Level indicator
        let levelLabel = SKLabelNode(fontNamed: "Courier")
        levelLabel.text = "УРОВЕНЬ 1"
        DesignSystem.apply(levelLabel, style: .subtitle, theme: theme)
        levelLabel.position = CGPoint(x: centerX,
                                      y: topY - (scoreLabel.frame.height + DesignSystem.layoutInterItemSpacing))
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.zPosition = 100
        addChild(levelLabel)
        
        // Difficulty indicator
        let diffLabel = SKLabelNode(fontNamed: "Courier")
        diffLabel.text = difficulty.name
        DesignSystem.apply(diffLabel, style: .footnote, theme: theme)
        diffLabel.fontColor = theme.skSecondary
        diffLabel.position = CGPoint(x: centerX,
                                     y: levelLabel.position.y - (levelLabel.frame.height + DesignSystem.layoutInterItemSpacing / 2))
        diffLabel.horizontalAlignmentMode = .center
        diffLabel.zPosition = 100
        addChild(diffLabel)
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
    
    private func spawnPipe(at x: CGFloat) {
        let gapSize = GameConfig.Level1.pipeGap * difficulty.gapMultiplier
        let minY = gapSize / 2 + 50
        let maxY = size.height - gapSize / 2 - 50
        let gapY = CGFloat.random(in: minY...maxY)
        
        let pipe = Pipe(x: x, gapY: gapY, gapSize: gapSize, theme: theme)
        addChild(pipe)
        pipes.append(pipe)
        
        // Spawn coin in the gap
        if Bool.random() {
            let coin = Coin(position: CGPoint(x: x, y: gapY), theme: theme)
            addChild(coin)
            coins.append(coin)
        }
        
        lastPipeX = x
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            return
        }
        
        if !isAIMode {
            player.flap()
            SoundManager.shared.playSound(.flap, on: self)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver || !player.isAlive {
            return
        }
        
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // AI mode
        if isAIMode {
            performAI()
        }
        
        // FLAPPY BIRD PHYSICS - постоянное падение вниз
        player.velocity.dy += GameConfig.Level1.gravity * difficulty.gravityMultiplier
        player.position.y += player.velocity.dy
        
        // Небольшое вращение корабля в зависимости от скорости
        if player.velocity.dy > 0 {
            // Летит вверх - наклон вверх
            player.zRotation = min(0.4, player.velocity.dy * 0.04)
        } else {
            // Падает вниз - наклон вниз
            player.zRotation = max(-0.5, player.velocity.dy * 0.06)
        }
        
        // Bounds check
        if player.position.y < 30 || player.position.y > size.height - 30 {
            gameOver()
            return
        }
        
        // Move pipes
        let scrollSpeed = GameConfig.Level1.scrollSpeed * difficulty.speedMultiplier
        for pipe in pipes {
            pipe.position.x -= scrollSpeed
            
            // Score when passing pipe
            if !pipe.isScored && pipe.position.x < player.position.x {
                pipe.isScored = true
                score += 1
                
                // Check for level completion
                if score >= GameConfig.Level1.scoreToAdvance {
                    levelComplete()
                    return
                }
            }
            
            // Remove off-screen pipes
            if pipe.position.x < -100 {
                pipe.removeFromParent()
                pipes.removeAll { $0 == pipe }
            }
        }
        
        // Spawn new pipes - найдём самую правую трубу
        if let rightmostPipe = pipes.max(by: { $0.position.x < $1.position.x }) {
            // Если самая правая труба достаточно далеко ушла влево, создаём новую
            if rightmostPipe.position.x < size.width - GameConfig.Level1.pipeSpacing {
                let newPipeX = rightmostPipe.position.x + GameConfig.Level1.pipeSpacing
                spawnPipe(at: newPipeX)
                lastPipeX = newPipeX
            }
        } else {
            // Если труб вообще нет, создаём первую
            spawnPipe(at: size.width + 100)
        }
        
        // Move and collect coins
        for coin in coins {
            coin.position.x -= scrollSpeed
            
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
            
            // Remove off-screen coins
            if coin.position.x < -50 {
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
        let currentTime = lastUpdateTime
        
        // AI может прыгать только раз в 0.3 секунды (чтобы не спамить)
        guard currentTime - lastAIJumpTime > 0.3 else { return }
        
        // AI logic: прыгаем когда падаем слишком низко
        let targetY = size.height / 2
        
        // Условия для прыжка:
        // 1. Летим ниже середины экрана И падаем быстро
        // 2. ИЛИ очень близко к земле
        let shouldJump = (player.position.y < targetY && player.velocity.dy < -1) ||
                        player.position.y < 150
        
        if shouldJump {
            player.flap()
            SoundManager.shared.playSound(.flap, on: self)
            lastAIJumpTime = currentTime
        }
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
        let message = "Выбери одно из трёх улучшений.\nСтоимость: \(GameConfig.Upgrade.coinCost) монет.\n💎 В банке: \(availableCoins)"
        let buttons = currentUpgradeOptions.map { upgrade in
            OverlayButtonConfig(title: upgrade.description.uppercased(),
                                name: "upgrade_\(upgrade.rawValue)")
        }
        OverlayFactory.presentModal(on: self,
                                    scene: self,
                                    theme: theme,
                                    title: "ВЫБОР УЛУЧШЕНИЯ",
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
                let scene = Level1Scene(size: nextSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            } else if nodeName == "menu" {
                let menuSize = view?.bounds.size ?? size
                let scene = MenuScene(size: menuSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            } else if nodeName == "next" {
                StoryManager.shared.presentPostLevelCutscene(from: self, level: 1, victory: true)
            } else if nodeName == "replay" {
                let scene = Level1Scene(size: size)
                scene.scaleMode = .aspectFill
                view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
            }
        }
    }
    
    private func applyUpgrade(_ upgrade: GameConfig.UpgradeType) {
        SoundManager.shared.playSound(.upgrade, on: self)
        
        switch upgrade {
        case .speed:
            player.speedMultiplier *= GameConfig.Upgrade.speedMultiplier
            
        case .size:
            player.sizeMultiplier *= GameConfig.Upgrade.sizeMultiplier
            player.setupForLevel(level: 1, theme: theme)
            
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
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == GameConfig.PhysicsCategory.player | GameConfig.PhysicsCategory.pipe {
            if player.hasShield {
                player.removeShield()
            } else {
                gameOver()
            }
        }
    }
    
    // АНИМАЦИЯ ВЗРЫВА И РАСКАЛЫВАНИЯ
    private func explodePlayer() {
        // Звук взрыва
        SoundManager.shared.playSound(.explosion, on: self)
        
        // 1. Большой взрыв частиц
        let explosion = ParticleEmitter.createExplosion(at: player.position, color: theme.skPrimary, count: 40)
        for particle in explosion {
            addChild(particle)
        }
        
        // 2. Раскалывание корабля на части
        let shipSize = GameConfig.Level1.playerSize
        let pieces = 6  // Количество частей
        
        for i in 0..<pieces {
            let angle = CGFloat(i) * (2 * .pi) / CGFloat(pieces)
            let pieceSize = CGSize(width: shipSize.width / 3, height: shipSize.height / 3)
            
            // Создаём кусочек корабля
            let piece = SKShapeNode(rectOf: pieceSize)
            piece.fillColor = theme.skPrimary
            piece.strokeColor = theme.skAccent
            piece.lineWidth = 2
            piece.glowWidth = 3
            piece.position = player.position
            piece.zRotation = angle
            piece.isAntialiased = false
            addChild(piece)
            
            // Разлетаются в разные стороны
            let velocity = CGVector(
                dx: cos(angle) * CGFloat.random(in: 8...15),
                dy: sin(angle) * CGFloat.random(in: 8...15)
            )
            
            let moveAction = SKAction.customAction(withDuration: 1.5) { node, elapsedTime in
                node.position.x += velocity.dx
                node.position.y += velocity.dy - elapsedTime * 5  // Гравитация
                node.zRotation += 0.2  // Вращение
            }
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let remove = SKAction.removeFromParent()
            piece.run(SKAction.sequence([moveAction, fadeOut, remove]))
        }
        
        // 3. Вспышка
        let flash = SKShapeNode(circleOfRadius: 60)
        flash.fillColor = theme.skAccent
        flash.strokeColor = .clear
        flash.alpha = 0.8
        flash.position = player.position
        flash.zPosition = 100
        addChild(flash)
        
        let expand = SKAction.scale(to: 3.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        flash.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))
        
        // 4. Удаляем оригинального игрока
        player.removeFromParent()
    }
    
    private func gameOver() {
        if isGameOver { return }
        isGameOver = true
        
        // Звук смерти
        SoundManager.shared.playSound(.die, on: self)
        
        // Красивая анимация смерти
        explodePlayer()
        
        // Update records (НЕ в AI режиме!)
        GameData.shared.updateHighScore(score, isAIMode: isAIMode)
        GameData.shared.updateLevelRecord(level: 1, score: score, isAIMode: isAIMode)
        if !isAIMode {
            GameData.shared.totalCoins += totalCoins
        }
        
        // Show game over screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showGameOverScreen()
        }
    }
    
    private func levelComplete() {
        isGameOver = true
        
        // Звук успешного прохождения уровня
        SoundManager.shared.playSound(.levelComplete, on: self)
        
        // Update data (НЕ в AI режиме!)
        GameData.shared.updateHighScore(score, isAIMode: isAIMode)
        GameData.shared.updateLevelRecord(level: 1, score: score, isAIMode: isAIMode)
        if !isAIMode {
            GameData.shared.totalCoins += totalCoins
            GameData.shared.currentLevel = 2
        }
        
        // Show completion screen
        showLevelCompleteScreen()
    }
    
    private func showGameOverScreen() {
        let message = StoryManager.shared.randomPostmortem()
        let buttons = [
            OverlayButtonConfig(title: "↻ ЗАНОВО", name: "retry"),
            OverlayButtonConfig(title: "◄ МЕНЮ", name: "menu")
        ]
        OverlayFactory.presentModal(on: self,
                                    scene: self,
                                    theme: theme,
                                    message: message,
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
        recap.text = "Шлюп прорвался через пояс. Продолжить полёт?"
        recap.fontSize = 22
        recap.fontColor = theme.skSecondary
        recap.position = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
        recap.zPosition = 301
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
        guard !lines.isEmpty else { return }
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
