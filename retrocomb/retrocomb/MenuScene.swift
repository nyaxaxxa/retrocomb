//
//  MenuScene.swift
//  retrocomb
//
//  Space Flappy Game - Main Menu
//

import SpriteKit
import UIKit

class MenuScene: SKScene {
    private var theme: ColorTheme = ColorTheme.classicGreen
    private var starField: [SKShapeNode] = []
    private let defaults = UserDefaults.standard
    
    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        setupScene()
        
        // Запускаем фоновую музыку меню
        SoundManager.shared.playBackgroundMusic(fileName: "menu_music.mp3")
    }
    
    private func setupScene() {
        // Проверяем, что размер сцены валидный
        if size.width <= 0 || size.height <= 0 {
            print("⚠️ MenuScene: Invalid scene size (\(size)), scene may not render correctly")
            // Продолжаем выполнение, но элементы могут быть неправильно позиционированы
        }
        
        let safeInsets = view?.safeAreaInsets ?? .zero
        backgroundColor = theme.skBackground
        
        // Reset background decor
        for star in starField {
            star.removeFromParent()
        }
        starField.removeAll()
        addRetroEffects(theme: theme)
        createStarField()
        
        let centerX = size.width / 2
        let contentWidth = DesignSystem.readableContentWidth(for: self)
        
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "▓▒░ SPACE FLAPPY ░▒▓"
        DesignSystem.apply(title, style: .largeTitle, theme: theme)
        title.preferredMaxLayoutWidth = contentWidth
        // Опускаем название ниже, чтобы не перекрывалось челкой iPhone
        let titleTopMargin = safeInsets.top + DesignSystem.layoutVerticalPadding * 2
        title.position = CGPoint(
            x: centerX,
            y: size.height - titleTopMargin - title.frame.height / 2
        )
        addChild(title)
        
        if let glowNode = title.copy() as? SKLabelNode {
            glowNode.fontColor = theme.skAccent
            glowNode.alpha = 0.5
            glowNode.setScale(1.02)
            glowNode.zPosition = title.zPosition - 1
            glowNode.position = title.position
            addChild(glowNode)
        }
        
        let subtitle = SKLabelNode(fontNamed: "Courier")
        subtitle.text = "[ ULTRA RETRO ARCADE ]"
        DesignSystem.apply(subtitle, style: .subtitle, theme: theme)
        subtitle.alpha = 0.85
        subtitle.preferredMaxLayoutWidth = contentWidth
        subtitle.position = CGPoint(
            x: centerX,
            y: title.position.y - subtitle.frame.height - DesignSystem.layoutInterItemSpacing
        )
        addChild(subtitle)
        
        // subtle glitch animation
        let glitchAction = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 3...6)),
            SKAction.run { RetroEffects.applyGlitchEffect(to: subtitle) }
        ])
        subtitle.run(SKAction.repeatForever(glitchAction))
        
        var yPosition = subtitle.position.y - (DesignSystem.layoutVerticalPadding + DesignSystem.buttonSize.height / 2)
        let buttonStep = DesignSystem.buttonSize.height + DesignSystem.layoutInterItemSpacing
        
        createButton(text: "► СТАРТ", position: CGPoint(x: centerX, y: yPosition), name: "start")
        yPosition -= buttonStep
        
        if GameData.shared.currentLevel > 1 {
            createButton(text: "► ПРОДОЛЖИТЬ", position: CGPoint(x: centerX, y: yPosition), name: "continue")
            yPosition -= buttonStep
        }
        
        createButton(text: "🎮 ВЫБОР УРОВНЯ", position: CGPoint(x: centerX, y: yPosition), name: "levelSelect")
        yPosition -= buttonStep
        
        let difficulty = GameData.shared.getCurrentDifficulty()
        createButton(text: "⚙️ СЛОЖНОСТЬ: \(difficulty.name)", position: CGPoint(x: centerX, y: yPosition), name: "difficulty")
        yPosition -= buttonStep
        
        createButton(text: "🎨 ТЕМА: \(theme.name)", position: CGPoint(x: centerX, y: yPosition), name: "theme")
        yPosition -= buttonStep
        
        createButton(text: "🏆 РЕКОРДЫ", position: CGPoint(x: centerX, y: yPosition), name: "leaderboard")
        
        let highScore = GameData.shared.highScore
        if highScore > 0 {
            let scoreLabel = SKLabelNode(fontNamed: "Courier")
            scoreLabel.text = "Лучший результат: \(highScore)"
            DesignSystem.apply(scoreLabel, style: .footnote, theme: theme)
            scoreLabel.preferredMaxLayoutWidth = contentWidth
            scoreLabel.position = CGPoint(
                x: centerX,
                y: safeInsets.bottom + DesignSystem.layoutVerticalPadding + scoreLabel.frame.height / 2
            )
            addChild(scoreLabel)
        }
        
        let scaleUp = SKAction.scale(to: 1.05, duration: 1.0)
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.0)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        title.run(SKAction.repeatForever(pulse))
    }
    
    private func createButton(text: String, position: CGPoint, name: String) {
        let adaptiveSize = DesignSystem.adaptiveButtonSize(for: self)
        let buttonSize = CGSize(width: adaptiveSize.width, height: adaptiveSize.height)
        let background = SKShapeNode(rectOf: buttonSize, cornerRadius: DesignSystem.cardCornerRadius)
        background.fillColor = theme.skBackground.withAlphaComponent(0.35)
        background.strokeColor = theme.skPrimary
        background.lineWidth = 2.5
        background.glowWidth = 4
        background.position = position
        background.name = name
        background.isAntialiased = false
        addChild(background)
        
        let highlight = SKShapeNode(rectOf: CGSize(width: buttonSize.width - 16,
                                                   height: buttonSize.height - 16),
                                    cornerRadius: DesignSystem.cardCornerRadius - 6)
        highlight.strokeColor = theme.skAccent.withAlphaComponent(0.35)
        highlight.fillColor = .clear
        highlight.lineWidth = 1.5
        highlight.alpha = 0.7
        background.addChild(highlight)
        
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        DesignSystem.apply(label, style: .button, theme: theme)
        label.preferredMaxLayoutWidth = buttonSize.width - DesignSystem.buttonContentInset * 2
        // Убеждаемся, что текст помещается в кнопку
        DesignSystem.fit(label, maxWidth: buttonSize.width - DesignSystem.buttonContentInset * 2, minFontSize: 14)
        label.position = .zero
        background.addChild(label)
        
        if let shadow = label.copy() as? SKLabelNode {
            shadow.fontColor = theme.skAccent.withAlphaComponent(0.3)
            shadow.position = CGPoint(x: 0, y: -2)
            shadow.zPosition = -1
            background.addChild(shadow)
        }
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        background.run(SKAction.repeatForever(pulse))
    }
    
    private func createStarField() {
        // ULTRA MODERN PIXEL STARS
        for i in 0..<120 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let starSize = CGFloat.random(in: 2...4)
            
            // Пиксельные квадратные звёзды вместо круглых
            let star = SKShapeNode(rectOf: CGSize(width: starSize, height: starSize))
            star.fillColor = theme.skPrimary.withAlphaComponent(CGFloat.random(in: 0.3...0.9))
            star.strokeColor = theme.skAccent.withAlphaComponent(0.5)
            star.lineWidth = 1
            star.position = CGPoint(x: x, y: y)
            star.glowWidth = starSize * 0.5
            star.isAntialiased = false  // Пиксельный стиль
            star.zPosition = -10 + CGFloat(i) / 120 * 5  // Разная глубина
            addChild(star)
            starField.append(star)
            
            // Разные типы анимаций для разнообразия
            if Bool.random() {
                // Мерцание
                let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 0.8...2.0))
                let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: Double.random(in: 0.8...2.0))
                let twinkle = SKAction.sequence([fadeOut, fadeIn])
                star.run(SKAction.repeatForever(twinkle))
            } else {
                // Пульсация свечения
                let glowUp = SKAction.customAction(withDuration: 2.0) { node, time in
                    if let shape = node as? SKShapeNode {
                        shape.glowWidth = starSize * (0.5 + sin(time * 3) * 0.3)
                    }
                }
                star.run(SKAction.repeatForever(glowUp))
            }
            
            // Случайная ротация для некоторых звёзд
            if Bool.random() {
                let rotate = SKAction.rotate(byAngle: .pi * 2, duration: Double.random(in: 4...8))
                star.run(SKAction.repeatForever(rotate))
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            guard let nodeName = node.name else { continue }
            
            // Animate button press
            let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            node.run(SKAction.sequence([scaleDown, scaleUp]))
            
            // Звук нажатия кнопки
            SoundManager.shared.playSound(.buttonClick, on: self)
            
            switch nodeName {
            case "start":
                startGame(level: 1)
                
            case "continue":
                let level = GameData.shared.currentLevel
                startGame(level: level)
                
            case "levelSelect":
                showLevelSelect()
                
            case "difficulty":
                cycleDifficulty()
                
            case "theme":
                cycleTheme()
                
            case "leaderboard":
                showLeaderboard()
                
            default:
                break
            }
        }
    }
    
    private func startGame(level: Int) {
        if StoryManager.shared.cutsceneBefore(level: level) != nil {
            StoryManager.shared.presentPreLevelCutscene(from: self, level: level)
            return
        }
        let targetSize = view?.bounds.size ?? size
        let scene = StoryManager.shared.scene(for: level, size: targetSize)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func showLevelSelect() {
        removeAllChildren()
        backgroundColor = theme.skBackground
        for star in starField { star.removeFromParent() }
        starField.removeAll()
        addRetroEffects(theme: theme)
        createStarField()
        
        let safeInsets = view?.safeAreaInsets ?? .zero
        let centerX = size.width / 2
        let contentWidth = DesignSystem.readableContentWidth(for: self)
        let adaptiveSize = DesignSystem.adaptiveButtonSize(for: self)
        let cardHeight = adaptiveSize.height * 1.35
        let cardStep = cardHeight + DesignSystem.layoutInterItemSpacing
        
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "ВЫБОР УРОВНЯ"
        DesignSystem.apply(title, style: .title, theme: theme)
        title.preferredMaxLayoutWidth = contentWidth
        title.position = CGPoint(
            x: centerX,
            y: size.height - safeInsets.top - DesignSystem.layoutVerticalPadding - title.frame.height / 2
        )
        addChild(title)
        
        // Вычисляем доступную высоту для кнопок
        let titleBottom = title.position.y - title.frame.height / 2
        let backButtonHeight = adaptiveSize.height
        let backButtonY = safeInsets.bottom + DesignSystem.layoutVerticalPadding + backButtonHeight / 2
        let maxContentHeight = titleBottom - backButtonY - backButtonHeight - DesignSystem.layoutVerticalPadding * 2
        
        // Проверяем, помещаются ли все кнопки
        let totalNeededHeight = cardStep * 6 - DesignSystem.layoutInterItemSpacing
        let needsScaling = totalNeededHeight > maxContentHeight
        
        var cardHeightToUse = cardHeight
        var cardStepToUse = cardStep
        if needsScaling {
            // Уменьшаем размеры карточек и отступы
            let scale = max(0.7, maxContentHeight / totalNeededHeight)
            cardHeightToUse = cardHeight * scale
            cardStepToUse = cardHeightToUse + DesignSystem.layoutInterItemSpacing * scale
        }
        
        var yPos = title.position.y - DesignSystem.layoutVerticalPadding - cardHeightToUse / 2
        
        createLevelButton(level: 1,
                          title: "Уровень 1: Classic Flappy",
                          record: GameData.shared.level1Record,
                          position: CGPoint(x: centerX, y: yPos))
        yPos -= cardStepToUse
        
        createLevelButton(level: 2,
                          title: "Уровень 2: Top-Down",
                          record: GameData.shared.level2Record,
                          position: CGPoint(x: centerX, y: yPos))
        yPos -= cardStepToUse
        
        createLevelButton(level: 3,
                          title: "Уровень 3: Open Space",
                          record: GameData.shared.level3Record,
                          position: CGPoint(x: centerX, y: yPos))
        yPos -= cardStepToUse
        
        createLevelButton(level: 4,
                          title: "Уровень 4: Landing Challenge 🚀",
                          record: GameData.shared.level4Record,
                          position: CGPoint(x: centerX, y: yPos))
        yPos -= cardStepToUse
        
        createLevelButton(level: 5,
                          title: "Уровень 5: Tower Defense ⚔️",
                          record: GameData.shared.level5Record,
                          position: CGPoint(x: centerX, y: yPos))
        yPos -= cardStepToUse
        
        createLevelButton(level: 6,
                          title: "Уровень 6: Neon Doom",
                          record: GameData.shared.level6Record,
                          position: CGPoint(x: centerX, y: yPos))
        
        createButton(text: "◄ НАЗАД", position: CGPoint(x: centerX, y: backButtonY), name: "back")
    }
    
    private func createLevelButton(level: Int, title: String, record: Int, position: CGPoint) {
        let adaptiveSize = DesignSystem.adaptiveButtonSize(for: self)
        let cardWidth = adaptiveSize.width
        // Вычисляем высоту карточки на основе позиции (если была применена масштабирование)
        let cardHeight = adaptiveSize.height * 1.35
        
        let container = SKNode()
        container.position = position
        container.name = "level\(level)"
        addChild(container)
        
        let background = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight),
                                     cornerRadius: DesignSystem.cardCornerRadius)
        background.fillColor = theme.skBackground.withAlphaComponent(0.3)
        background.strokeColor = theme.skPrimary
        background.lineWidth = 2.5
        background.glowWidth = 3
        container.addChild(background)
        
        let titleLabel = SKLabelNode(fontNamed: "Courier-Bold")
        titleLabel.text = title
        DesignSystem.apply(titleLabel, style: .body, theme: theme)
        titleLabel.preferredMaxLayoutWidth = cardWidth - DesignSystem.buttonContentInset * 2
        // Убеждаемся, что текст помещается в кнопку
        DesignSystem.fit(titleLabel, maxWidth: cardWidth - DesignSystem.buttonContentInset * 2, minFontSize: 12)
        titleLabel.position = CGPoint(x: 0, y: cardHeight * 0.2)
        container.addChild(titleLabel)
        
        let recordLabel = SKLabelNode(fontNamed: "Courier")
        if record > 0 {
            recordLabel.text = "Рекорд: \(record)"
        } else {
            recordLabel.text = "Рекорд ещё не установлен"
        }
        DesignSystem.apply(recordLabel, style: .footnote, theme: theme)
        recordLabel.preferredMaxLayoutWidth = cardWidth - DesignSystem.buttonContentInset * 2
        // Убеждаемся, что текст помещается в кнопку
        DesignSystem.fit(recordLabel, maxWidth: cardWidth - DesignSystem.buttonContentInset * 2, minFontSize: 10)
        recordLabel.position = CGPoint(x: 0, y: -cardHeight * 0.2)
        container.addChild(recordLabel)
    }
    
    private func createLockedLevelButton(level: Int, title: String, position: CGPoint) {
        let adaptiveSize = DesignSystem.adaptiveButtonSize(for: self)
        let cardWidth = adaptiveSize.width
        let cardHeight = adaptiveSize.height * 1.35
        
        let container = SKNode()
        container.position = position
        container.name = "locked\(level)"
        addChild(container)
        
        let background = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight),
                                     cornerRadius: DesignSystem.cardCornerRadius)
        background.fillColor = theme.skBackground.withAlphaComponent(0.15)
        background.strokeColor = theme.skPrimary.withAlphaComponent(0.4)
        background.lineWidth = 2
        container.addChild(background)
        
        let titleLabel = SKLabelNode(fontNamed: "Courier-Bold")
        titleLabel.text = title
        DesignSystem.apply(titleLabel, style: .body, theme: theme)
        titleLabel.fontColor = theme.skPrimary.withAlphaComponent(0.6)
        titleLabel.preferredMaxLayoutWidth = cardWidth - DesignSystem.buttonContentInset * 2
        titleLabel.position = CGPoint(x: 0, y: cardHeight * 0.2)
        container.addChild(titleLabel)
        
        let hint = SKLabelNode(fontNamed: "Courier")
        hint.text = "Пройди уровень 3 с 25+ очками"
        DesignSystem.apply(hint, style: .footnote, theme: theme)
        hint.fontColor = theme.skSecondary.withAlphaComponent(0.5)
        hint.preferredMaxLayoutWidth = cardWidth - DesignSystem.buttonContentInset * 2
        hint.position = CGPoint(x: 0, y: -cardHeight * 0.2)
        container.addChild(hint)
    }
    
    private func cycleDifficulty() {
        let currentDiff = GameData.shared.currentDifficulty
        let nextValue = (currentDiff + 1) % (GameConfig.Difficulty.ai.rawValue + 1)
        GameData.shared.currentDifficulty = nextValue
        
        // Refresh menu
        removeAllChildren()
        setupScene()
    }
    
    private func cycleTheme() {
        let currentIndex = GameData.shared.currentThemeIndex
        let nextIndex = (currentIndex + 1) % ColorTheme.allThemes.count
        GameData.shared.currentThemeIndex = nextIndex
        theme = ColorTheme.allThemes[nextIndex]
        
        // Refresh menu
        removeAllChildren()
        setupScene()
    }
    
    private func showLeaderboard() {
        removeAllChildren()
        backgroundColor = theme.skBackground
        for star in starField { star.removeFromParent() }
        starField.removeAll()
        addRetroEffects(theme: theme)
        createStarField()
        
        let safeInsets = view?.safeAreaInsets ?? .zero
        let centerX = size.width / 2
        let contentWidth = DesignSystem.readableContentWidth(for: self)
        let adaptiveSize = DesignSystem.adaptiveButtonSize(for: self)
        
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "🏆 ТАБЛИЦА РЕКОРДОВ"
        DesignSystem.apply(title, style: .title, theme: theme)
        title.preferredMaxLayoutWidth = contentWidth
        title.position = CGPoint(
            x: centerX,
            y: size.height - safeInsets.top - DesignSystem.layoutVerticalPadding - title.frame.height / 2
        )
        addChild(title)
        
        // Вычисляем доступную высоту для записей
        let titleBottom = title.position.y - title.frame.height / 2
        let backButtonHeight = adaptiveSize.height
        let backButtonY = safeInsets.bottom + DesignSystem.layoutVerticalPadding + backButtonHeight / 2
        let maxContentHeight = titleBottom - backButtonY - backButtonHeight - DesignSystem.layoutVerticalPadding * 2
        
        // Получаем актуальные данные таблицы рекордов (обновляем перед показом)
        let leaderboard = GameData.shared.leaderboard
        var currentY = title.position.y - DesignSystem.layoutVerticalPadding
        
        if leaderboard.isEmpty {
            let emptyLabel = SKLabelNode(fontNamed: "Courier")
            emptyLabel.text = "Пока нет рекордов"
            DesignSystem.apply(emptyLabel, style: .body, theme: theme)
            emptyLabel.preferredMaxLayoutWidth = contentWidth
            emptyLabel.position = CGPoint(x: centerX, y: currentY)
            addChild(emptyLabel)
        } else {
            // Ограничиваем количество записей, которые помещаются на экран
            let entries = Array(leaderboard.prefix(10))
            let minEntryHeight = DesignSystem.font(for: .body).pointSize + DesignSystem.layoutInterItemSpacing
            let maxEntries = max(1, Int(maxContentHeight / minEntryHeight))
            let entriesToShow = Array(entries.prefix(maxEntries))
            
            for (index, entry) in entriesToShow.enumerated() {
                let entryLabel = SKLabelNode(fontNamed: "Courier")
                entryLabel.text = "\(index + 1). \(entry.name) - \(entry.score) очков (Уровень \(entry.level))"
                DesignSystem.apply(entryLabel, style: .body, theme: theme)
                entryLabel.preferredMaxLayoutWidth = contentWidth
                DesignSystem.fit(entryLabel, maxWidth: contentWidth, minFontSize: 12)
                entryLabel.position = CGPoint(x: centerX, y: currentY)
                addChild(entryLabel)
                
                currentY -= entryLabel.frame.height + DesignSystem.layoutInterItemSpacing
                
                // Проверяем, не выходим ли за пределы экрана
                if currentY < backButtonY + backButtonHeight + DesignSystem.layoutVerticalPadding {
                    break
                }
            }
        }
        
        createButton(text: "◄ НАЗАД", position: CGPoint(x: centerX, y: backButtonY), name: "back")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            guard let nodeName = node.name else { continue }
            
            if nodeName == "back" {
                // Возврат в главное меню - обновляем данные перед показом
                removeAllChildren()
                setupScene()
            } else if nodeName.hasPrefix("level") {
                if let levelNum = Int(nodeName.replacingOccurrences(of: "level", with: "")) {
                    startGame(level: levelNum)
                }
            }
        }
    }
}
