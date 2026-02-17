//
//  Level4Scene.swift
//  retrocomb
//
//  Space Flappy Game - Level 4 (Landing Simulator)
//

import Foundation
import SpriteKit
import UIKit

class Level4Scene: SKScene, SKPhysicsContactDelegate {
    private enum ControlZone {
        case main
        case left
        case right
    }
    
    private var theme: ColorTheme = .classicGreen
    private var difficulty: GameConfig.Difficulty = .normal
    
    // Spaceship
    private var spaceship: SKNode!
    private var flameNode: SKShapeNode!
    private var leftGear: SKShapeNode!
    private var rightGear: SKShapeNode!
    private var gearExtended = false
    
    // Controls
    private var isMainThrustActive = false
    private var isLeftThrustActive = false
    private var isRightThrustActive = false
    private var touchZones: [UITouch: ControlZone] = [:]
    private var lastAITouchTime: TimeInterval = 0
    
    // Terrain
    private var terrainNode: SKShapeNode!
    private var safeZoneNode: SKShapeNode!
    private var terrainPoints: [CGPoint] = []
    private var safeZoneRange: ClosedRange<CGFloat> = 0...0
    private var worldNode: SKNode!
    private var worldCamera: SKCameraNode!
    
    // HUD
    private var hudBackground: SKShapeNode!
    private var fuelLabel: SKLabelNode!
    private var velocityLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    
    // Game state
    private var fuel: CGFloat = GameConfig.Level4.fuelCapacity
    private var elapsedTime: TimeInterval = 0
    private var windForce: CGFloat = 0
    private var windTimer: TimeInterval = 0
    private var isGameOver = false
    private var hasLanded = false
    private var landingScore: Int = 0
    private var lastUpdateTime: TimeInterval = 0
    private var safeInsets: UIEdgeInsets = .zero
    private var targetWindForce: CGFloat = 0
    private var smoothedWindForce: CGFloat = 0
    
    // Virtual controls
    private var thrustButton: SKShapeNode!
    private var leftButton: SKShapeNode!
    private var rightButton: SKShapeNode!
    private let controlsNode = SKNode()
    
    private var isAIMode: Bool {
        difficulty == .ai
    }
    
    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        difficulty = GameData.shared.getCurrentDifficulty()
        // Темный космический фон вместо зеленого
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1.0)
        physicsWorld.gravity = GameConfig.Level4.gravity
        physicsWorld.contactDelegate = self
        safeInsets = view.safeAreaInsets
        physicsWorld.speed = 0.5
        
        // Запускаем фоновую музыку
        SoundManager.shared.playBackgroundMusic(fileName: "retro_music.mp3")
        
        // Создаём камеру для большого мира
        worldCamera = SKCameraNode()
        self.camera = worldCamera
        addChild(worldCamera)
        
        // Убираем зеленые эффекты, используем темный космический фон
        setupHUD()
        createTerrain()
        worldNode.speed = 0.5
        createSpaceship()
        controlsNode.zPosition = 120
        controlsNode.removeAllChildren()
        if controlsNode.parent == nil {
            worldCamera.addChild(controlsNode)
        }
        setupControls()
        showInstructions()
        updateHUD()
    }
    
    override func willMove(from view: SKView) {
        // Останавливаем звук двигателя при выходе из сцены
        SoundManager.shared.stopEngineLoop()
        super.willMove(from: view)
    }
    
    // MARK: - Setup
    private func setupHUD() {
        let hudHeight: CGFloat = 72
        let hudWidth = DesignSystem.readableContentWidth(for: self, extraMargin: -40)
        let topSafeY = size.height / 2 - safeInsets.top - DesignSystem.layoutVerticalPadding
        let centerOffsetX = (safeInsets.left - safeInsets.right) / 2
        
        hudBackground = SKShapeNode(rectOf: CGSize(width: hudWidth, height: hudHeight), cornerRadius: 10)
        hudBackground.fillColor = theme.skBackground.withAlphaComponent(0.78)
        hudBackground.strokeColor = theme.skPrimary
        hudBackground.lineWidth = 2
        hudBackground.glowWidth = 3
        hudBackground.isAntialiased = false
        hudBackground.position = CGPoint(x: centerOffsetX, y: topSafeY - hudHeight / 2)
        hudBackground.zPosition = 50
        worldCamera.addChild(hudBackground)
        
        let labelTopY = topSafeY - 4
        let labelBottomY = hudBackground.position.y - hudHeight / 2 + DesignSystem.layoutInterItemSpacing
        
        fuelLabel = SKLabelNode(fontNamed: "Courier-Bold")
        fuelLabel.fontColor = theme.skAccent
        fuelLabel.fontSize = 20
        fuelLabel.horizontalAlignmentMode = .left
        fuelLabel.verticalAlignmentMode = .top
        fuelLabel.position = CGPoint(x: -size.width / 2 + safeInsets.left + DesignSystem.layoutHorizontalPadding,
                                     y: labelTopY)
        fuelLabel.zPosition = 60
        worldCamera.addChild(fuelLabel)
        
        velocityLabel = SKLabelNode(fontNamed: "Courier-Bold")
        velocityLabel.fontColor = theme.skSecondary
        velocityLabel.fontSize = 20
        velocityLabel.horizontalAlignmentMode = .right
        velocityLabel.verticalAlignmentMode = .top
        velocityLabel.position = CGPoint(x: size.width / 2 - safeInsets.right - DesignSystem.layoutHorizontalPadding,
                                         y: labelTopY)
        velocityLabel.zPosition = 60
        worldCamera.addChild(velocityLabel)
        
        statusLabel = SKLabelNode(fontNamed: "Courier")
        statusLabel.fontColor = theme.skPrimary
        statusLabel.fontSize = 16
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .top
        statusLabel.position = CGPoint(x: centerOffsetX, y: labelBottomY)
        statusLabel.zPosition = 60
        statusLabel.preferredMaxLayoutWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 20)
        wrapLabel(statusLabel, maxWidth: statusLabel.preferredMaxLayoutWidth)
        worldCamera.addChild(statusLabel)
        
        instructionLabel = SKLabelNode(fontNamed: "Courier")
        instructionLabel.fontColor = theme.skText.withAlphaComponent(0.9)
        instructionLabel.fontSize = 16
        instructionLabel.horizontalAlignmentMode = .center
        instructionLabel.verticalAlignmentMode = .bottom
        let bottomSafeY = -size.height / 2 + safeInsets.bottom + DesignSystem.layoutVerticalPadding
        instructionLabel.position = CGPoint(x: centerOffsetX,
                                            y: bottomSafeY + DesignSystem.buttonSize.height + DesignSystem.layoutInterItemSpacing)
        instructionLabel.zPosition = 60
        instructionLabel.preferredMaxLayoutWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 40)
        wrapLabel(instructionLabel, maxWidth: instructionLabel.preferredMaxLayoutWidth)
        worldCamera.addChild(instructionLabel)
    }
    
    private func setupControls() {
        controlsNode.removeAllChildren()
        
        let availableWidth = size.width - safeInsets.left - safeInsets.right
        let availableHeight = size.height - safeInsets.top - safeInsets.bottom
        let baseDimension = max(48, min(availableWidth, availableHeight) * 0.12)
        var lateralSide = min(84, baseDimension)
        var lateralSize = CGSize(width: lateralSide, height: lateralSide)
        var thrustSize = CGSize(width: lateralSide * 1.35,
                                height: lateralSide * 1.65)
        
        let centerOffsetX = (safeInsets.left - safeInsets.right) / 2
        var spacing = max(12, DesignSystem.layoutInterItemSpacing * 0.75)
        var totalWidth = lateralSize.width + thrustSize.width + lateralSize.width + spacing * 2
        
        // Проверяем, помещаются ли кнопки на экран
        let minSpacing: CGFloat = 8
        let maxUsableWidth = availableWidth - DesignSystem.layoutHorizontalPadding * 2
        if totalWidth > maxUsableWidth {
            // Вычисляем масштаб для умещения всех кнопок
            let scale = max(0.7, maxUsableWidth / totalWidth)
            lateralSide = max(44, lateralSide * scale)
            lateralSize = CGSize(width: lateralSide, height: lateralSide)
            thrustSize = CGSize(width: lateralSide * 1.35, height: lateralSide * 1.65)
            spacing = max(minSpacing, spacing * scale)
            totalWidth = lateralSize.width + thrustSize.width + lateralSize.width + spacing * 2
        }
        
        let controlHeight = max(lateralSize.height, thrustSize.height)
        let bottomY = -size.height / 2 + safeInsets.bottom + DesignSystem.layoutVerticalPadding + controlHeight / 2
        let startX = centerOffsetX - totalWidth / 2
        
        leftButton = makeControlButton(symbol: "⟵", caption: "ЛЕВО", size: lateralSize)
        leftButton.position = CGPoint(x: startX + lateralSize.width / 2, y: bottomY)
        leftButton.name = "control_left"
        controlsNode.addChild(leftButton)
        
        rightButton = makeControlButton(symbol: "⟶", caption: "ПРАВО", size: lateralSize)
        rightButton.position = CGPoint(x: startX + lateralSize.width + spacing + thrustSize.width + spacing + lateralSize.width / 2,
                                       y: bottomY)
        rightButton.name = "control_right"
        controlsNode.addChild(rightButton)
        
        thrustButton = makeControlButton(symbol: "▲", caption: "ГАЗ", size: thrustSize)
        thrustButton.position = CGPoint(x: startX + lateralSize.width + spacing + thrustSize.width / 2,
                                        y: bottomY)
        thrustButton.name = "control_thrust"
        controlsNode.addChild(thrustButton)
        
        let highestControlTop = bottomY + controlHeight / 2
        let desiredInstructionY = highestControlTop + DesignSystem.layoutInterItemSpacing * 1.2 + instructionLabel.frame.height / 2
        let maxInstructionY = size.height / 2 - safeInsets.top - DesignSystem.layoutVerticalPadding - instructionLabel.frame.height / 2
        instructionLabel.position.y = min(desiredInstructionY, maxInstructionY)
    }
    
    private func makeControlButton(symbol: String, caption: String, size: CGSize) -> SKShapeNode {
        let button = SKShapeNode(rectOf: size, cornerRadius: DesignSystem.cardCornerRadius)
        button.fillColor = theme.skBackground.withAlphaComponent(0.25)
        button.strokeColor = theme.skPrimary.withAlphaComponent(0.9)
        button.lineWidth = 2.5
        button.glowWidth = max(3, size.height * 0.08)
        button.isAntialiased = false
        button.zPosition = 120
        
        let icon = SKLabelNode(fontNamed: "Courier-Bold")
        icon.text = symbol
        DesignSystem.apply(icon, style: .title, theme: theme)
        icon.fontSize = min(icon.fontSize, size.height * 0.55)
        icon.position = CGPoint(x: 0, y: size.height * 0.14)
        icon.name = "icon"
        button.addChild(icon)
        
        let captionNode = SKLabelNode(fontNamed: "Courier")
        captionNode.text = caption
        DesignSystem.apply(captionNode, style: .footnote, theme: theme)
        captionNode.fontColor = theme.skSecondary
        captionNode.fontSize = min(captionNode.fontSize, size.height * 0.28)
        captionNode.position = CGPoint(x: 0, y: -size.height * 0.36)
        captionNode.name = "caption"
        button.addChild(captionNode)
        
        return button
    }
    
    private func updateControlButton(_ button: SKShapeNode?, highlighted: Bool) {
        guard let button else { return }
        let targetFill = highlighted ? theme.skAccent.withAlphaComponent(0.35) : theme.skBackground.withAlphaComponent(0.25)
        let caption = button.childNode(withName: "caption") as? SKLabelNode
        caption?.fontColor = highlighted ? theme.skPrimary : theme.skSecondary
        button.fillColor = targetFill
    }
    
    private func setControlsVisible(_ visible: Bool) {
        controlsNode.alpha = visible ? 1 : 0
        thrustButton?.alpha = visible ? 1 : 0
        leftButton?.alpha = visible ? 1 : 0
        rightButton?.alpha = visible ? 1 : 0
    }
    
    private func createTerrain() {
        let worldScale = GameConfig.Level4.worldScale
        let baseY: CGFloat = 120 * worldScale
        let segmentWidth = GameConfig.Level4.terrainSegmentWidth
        let safeWidth = GameConfig.Level4.safeZoneWidth * worldScale
        let worldWidth = size.width * worldScale
        
        // Случайная позиция посадочной площадки - дальше от центра для увеличения расстояния
        let distanceMultiplier = GameConfig.Level4.initialDistanceMultiplier
        let minSafeX = safeWidth / 2 + 200 * distanceMultiplier
        let maxSafeX = worldWidth - safeWidth / 2 - 200 * distanceMultiplier
        // Увеличиваем расстояние до точки посадки - размещаем её дальше от стартовой позиции
        let centerX = worldWidth / 2
        let startX = size.width * worldScale / 2
        let offset = worldWidth * 0.3 * distanceMultiplier  // Смещаем дальше от центра
        
        // Выбираем позицию посадки так, чтобы она была дальше от старта по диагонали
        let safeCenterX: CGFloat
        if startX < centerX {
            // Старт слева от центра - посадка справа (дальше)
            let rightMin = max(minSafeX, centerX + offset * 0.5)
            let rightMax = min(maxSafeX, worldWidth - safeWidth / 2 - 100)
            // Проверяем, что диапазон валидный
            if rightMin < rightMax {
                safeCenterX = CGFloat.random(in: rightMin...rightMax)
            } else {
                // Fallback на случайную позицию справа от центра
                safeCenterX = CGFloat.random(in: max(minSafeX, centerX)...maxSafeX)
            }
        } else {
            // Старт справа от центра - посадка слева (дальше)
            let leftMin = max(safeWidth / 2 + 100, minSafeX)
            let leftMax = min(maxSafeX, centerX - offset * 0.5)
            // Проверяем, что диапазон валидный
            if leftMin < leftMax {
                safeCenterX = CGFloat.random(in: leftMin...leftMax)
            } else {
                // Fallback на случайную позицию слева от центра
                safeCenterX = CGFloat.random(in: minSafeX...min(maxSafeX, centerX))
            }
        }
        let safeStart = safeCenterX - safeWidth / 2
        let safeEnd = safeCenterX + safeWidth / 2
        let tolerance = GameConfig.Level4.safeZoneTolerance * worldScale
        safeZoneRange = (safeStart - tolerance)...(safeEnd + tolerance)
        
        terrainPoints = []
        terrainPoints.append(CGPoint(x: -300, y: baseY))
        
        var x: CGFloat = 0
        while x <= worldWidth + 300 {
            let y: CGFloat
            if safeZoneRange.contains(x) {
                y = baseY
            } else {
                let noise = sin(x / 120) * 70 * worldScale + CGFloat.random(in: -60...60)
                y = max(50, baseY + noise)
            }
            terrainPoints.append(CGPoint(x: x, y: y))
            x += segmentWidth
        }
        terrainPoints.append(CGPoint(x: worldWidth + 300, y: baseY))
        
        let path = CGMutablePath()
        path.move(to: terrainPoints.first!)
        for point in terrainPoints.dropFirst() {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: worldWidth + 300, y: -300))
        path.addLine(to: CGPoint(x: -300, y: -300))
        path.closeSubpath()
        
        terrainNode = SKShapeNode(path: path)
        terrainNode.fillColor = theme.skPrimary.withAlphaComponent(0.6)
        terrainNode.strokeColor = theme.skPrimary
        terrainNode.lineWidth = 2
        terrainNode.glowWidth = 4
        terrainNode.isAntialiased = false
        terrainNode.zPosition = 5
        
        // Контейнер для большого мира
        worldNode = SKNode()
        worldNode.addChild(terrainNode)
        worldNode.setScale(1.0 / worldScale)
        worldNode.position = .zero
        addChild(worldNode)
        
        let groundBodyPath = CGMutablePath()
        groundBodyPath.move(to: terrainPoints.first!)
        for point in terrainPoints.dropFirst() {
            groundBodyPath.addLine(to: point)
        }
        terrainNode.physicsBody = SKPhysicsBody(edgeChainFrom: groundBodyPath)
        terrainNode.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.pipe
        terrainNode.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.player
        terrainNode.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.player
        
        safeZoneNode = SKShapeNode(rectOf: CGSize(width: safeWidth, height: 16))
        safeZoneNode.fillColor = theme.skAccent.withAlphaComponent(0.4)
        safeZoneNode.strokeColor = theme.skAccent
        safeZoneNode.lineWidth = 3
        safeZoneNode.glowWidth = 5
        safeZoneNode.position = CGPoint(x: safeCenterX, y: baseY + 8)
        safeZoneNode.isAntialiased = false
        safeZoneNode.zPosition = 6
        terrainNode.addChild(safeZoneNode)
        
        // Маркеры посадочной зоны (для навигации)
        let leftMarker = SKShapeNode(rectOf: CGSize(width: 10, height: 50))
        leftMarker.fillColor = theme.skAccent
        leftMarker.strokeColor = theme.skPrimary
        leftMarker.lineWidth = 2
        leftMarker.position = CGPoint(x: safeStart, y: baseY + 40)
        leftMarker.zPosition = 7
        leftMarker.isAntialiased = false
        terrainNode.addChild(leftMarker)
        
        let rightMarker = SKShapeNode(rectOf: CGSize(width: 10, height: 50))
        rightMarker.fillColor = theme.skAccent
        rightMarker.strokeColor = theme.skPrimary
        rightMarker.lineWidth = 2
        rightMarker.position = CGPoint(x: safeEnd, y: baseY + 40)
        rightMarker.zPosition = 7
        rightMarker.isAntialiased = false
        terrainNode.addChild(rightMarker)
    }
    
    private func createSpaceship() {
        let shipScale = GameConfig.Level4.shipScale
        let worldScale = GameConfig.Level4.worldScale
        let bodySize = CGSize(width: 60, height: 110)
        
        spaceship = SKNode()
        // Стартовая позиция - увеличиваем расстояние по диагонали до точки посадки
        let startX = size.width * worldScale / 2
        let startY = (size.height - 160) * worldScale * 1.15  // Немного выше для большего расстояния
        spaceship.position = CGPoint(x: startX, y: startY)
        spaceship.setScale(shipScale)
        
        // Добавляем в world node
        worldNode.addChild(spaceship)
        
        let body = SKShapeNode(rectOf: bodySize, cornerRadius: 12)
        body.fillColor = theme.skPrimary
        body.strokeColor = theme.skAccent
        body.lineWidth = 3
        body.glowWidth = 5
        body.isAntialiased = false
        body.zPosition = 20
        spaceship.addChild(body)
        
        flameNode = SKShapeNode(rectOf: CGSize(width: 20, height: 40))
        flameNode.fillColor = theme.skAccent.withAlphaComponent(0.7)
        flameNode.strokeColor = .clear
        flameNode.position = CGPoint(x: 0, y: -bodySize.height / 2 - 20)
        flameNode.isHidden = true
        flameNode.zPosition = 18
        spaceship.addChild(flameNode)
        
        let physicsBody = SKPhysicsBody(rectangleOf: bodySize)
        physicsBody.mass = 3.5  // Тяжелее для баллистики
        physicsBody.angularDamping = 1.2  // Меньше затухание вращения
        physicsBody.linearDamping = GameConfig.Level4.airResistance  // Низкое сопротивление = больше инерция
        physicsBody.allowsRotation = true
        physicsBody.restitution = 0.1  // Небольшой отскок
        physicsBody.categoryBitMask = GameConfig.PhysicsCategory.player
        physicsBody.contactTestBitMask = GameConfig.PhysicsCategory.pipe
        physicsBody.collisionBitMask = GameConfig.PhysicsCategory.pipe
        spaceship.physicsBody = physicsBody
        
        // Landing gear (initially retracted)
        let gearSize = CGSize(width: 12, height: 44)
        leftGear = SKShapeNode(rectOf: gearSize)
        leftGear.fillColor = theme.skSecondary
        leftGear.strokeColor = theme.skPrimary
        leftGear.lineWidth = 2
        leftGear.position = CGPoint(x: -bodySize.width / 2 + 12, y: -bodySize.height / 2)
        leftGear.isAntialiased = false
        leftGear.yScale = 0.05
        leftGear.zPosition = 19
        spaceship.addChild(leftGear)
        
        rightGear = leftGear.copy() as? SKShapeNode
        rightGear?.position = CGPoint(x: bodySize.width / 2 - 12, y: -bodySize.height / 2)
        if let rightGear = rightGear {
            spaceship.addChild(rightGear)
        }
    }
    
    private func showInstructions() {
        instructionLabel.text = "⚠️ КНОПКИ: ГАЗ — тяга | ЛЕВО / ПРАВО — стабилизация"
        wrapLabel(instructionLabel, maxWidth: instructionLabel.preferredMaxLayoutWidth)
        statusLabel.text = "Ветер: 0 | Ищите посадочную площадку!"
        wrapLabel(statusLabel, maxWidth: DesignSystem.readableContentWidth(for: self, extraMargin: 40))
        
        // Стрелка к посадочной зоне
        let arrow = SKLabelNode(fontNamed: "Courier-Bold")
        arrow.text = "▼"
        arrow.fontSize = 32
        arrow.fontColor = theme.skAccent
        arrow.position = CGPoint(x: 0, y: size.height / 2 - safeInsets.top - 140)
        arrow.zPosition = 65
        arrow.name = "landingArrow"
        worldCamera.addChild(arrow)
        
        // Анимация стрелки
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])
        arrow.run(SKAction.repeatForever(pulse))
    }
    
    private func updateHUD() {
        let safeInsets = view?.safeAreaInsets ?? .zero
        let halfWidth = size.width / 2
        let leftMaxWidth = halfWidth - safeInsets.left - DesignSystem.layoutHorizontalPadding
        let rightMaxWidth = halfWidth - safeInsets.right - DesignSystem.layoutHorizontalPadding
        
        let fuelPercent = max(0, fuel / GameConfig.Level4.fuelCapacity * 100)
        fuelLabel.text = String(format: "Топливо: %.0f%%", fuelPercent)
        DesignSystem.fit(fuelLabel, maxWidth: leftMaxWidth)
        if let velocity = spaceship.physicsBody?.velocity {
            let vertical = velocity.dy
            let horizontal = velocity.dx
            velocityLabel.text = String(format: "V: %+.0f↑ %+.0f→", vertical, horizontal)
            DesignSystem.fit(velocityLabel, maxWidth: rightMaxWidth)
        }
        
        // Обновляем стрелку направления к посадочной зоне
        if let arrow = worldCamera.childNode(withName: "landingArrow") as? SKLabelNode {
            let worldScale = GameConfig.Level4.worldScale
            let safeCenterX = (safeZoneRange.lowerBound + safeZoneRange.upperBound) / 2
            let scaledSafeCenterX = safeCenterX / worldScale
            let scaledShipX = spaceship.position.x / worldScale
            let deltaX = scaledSafeCenterX - scaledShipX
            
            // Если далеко - показываем стрелку
            if abs(deltaX) > 150 {
                arrow.alpha = 1.0
                arrow.text = deltaX > 0 ? "►" : "◄"
            } else {
                arrow.alpha = 0.3
                arrow.text = "▼"
            }
        }
    }
    
    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        guard !isAIMode else { return }
        for touch in touches {
            if let zone = zone(for: touch.location(in: self)) {
                touchZones[touch] = zone
                set(zone: zone, active: true)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        guard !isAIMode else { return }
        for touch in touches {
            let currentZone = zone(for: touch.location(in: self))
            if touchZones[touch] != currentZone {
                if let previous = touchZones[touch] {
                    set(zone: previous, active: false)
                }
                if let currentZone {
                    touchZones[touch] = currentZone
                    set(zone: currentZone, active: true)
                } else {
                    touchZones.removeValue(forKey: touch)
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isAIMode else { return }
        for touch in touches {
            if let zone = touchZones[touch] {
                set(zone: zone, active: false)
                touchZones.removeValue(forKey: touch)
            }
        }
        guard isGameOver else { return }
        if let touch = touches.first {
            handleOverlayTap(at: touch.location(in: self))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    private func zone(for location: CGPoint) -> ControlZone? {
        let localPoint = worldCamera.convert(location, from: self)
        if thrustButton?.contains(localPoint) == true { return .main }
        if leftButton?.contains(localPoint) == true { return .left }
        if rightButton?.contains(localPoint) == true { return .right }
        return nil
    }
    
    private func set(zone: ControlZone, active: Bool) {
        switch zone {
        case .main:
            if active && fuel <= 0 {
                isMainThrustActive = false
                flameNode.isHidden = true
                updateControlButton(thrustButton, highlighted: false)
                SoundManager.shared.stopEngineLoop()
                return
            }
            
            let wasActive = isMainThrustActive
            isMainThrustActive = active
            flameNode.isHidden = !active
            updateControlButton(thrustButton, highlighted: isMainThrustActive)
            
            // Звуки двигателя
            if active && !wasActive {
                // Включение двигателя
                SoundManager.shared.playSound(.engineStart, on: self)
                SoundManager.shared.startEngineLoop()
            } else if !active && wasActive {
                // Выключение двигателя
                SoundManager.shared.stopEngineLoop()
            }
            
        case .left:
            isLeftThrustActive = active && fuel > 0
            updateControlButton(leftButton, highlighted: isLeftThrustActive)
        case .right:
            isRightThrustActive = active && fuel > 0
            updateControlButton(rightButton, highlighted: isRightThrustActive)
        }
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        let deltaTime = lastUpdateTime == 0 ? 0.016 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        elapsedTime += deltaTime
        
        updateWind(deltaTime: deltaTime)
        applyControls(deltaTime: deltaTime)
        constrainSpaceshipToWorld()  // Ограничиваем корабль границами мира
        extendGearIfNeeded()
        updateHUD()
        updateCamera(deltaTime: deltaTime)
        
        if isAIMode {
            runAI(deltaTime: deltaTime, currentTime: currentTime)
        }
    }
    
    private func constrainSpaceshipToWorld() {
        guard let body = spaceship.physicsBody else { return }
        let worldScale = GameConfig.Level4.worldScale
        let worldWidth = size.width * worldScale
        let worldHeight = size.height * worldScale
        
        // Границы мира с небольшим отступом
        // Корабль находится в worldNode, который имеет scale 1.0/worldScale,
        // но позиции корабля уже в масштабированных координатах мира
        let margin: CGFloat = 100  // Отступ от краев
        let minX = margin
        let maxX = worldWidth - margin
        let minY: CGFloat = 50  // Не даем упасть слишком низко
        let maxY = worldHeight - margin
        
        // Получаем текущую позицию корабля (в координатах мира)
        var position = spaceship.position
        var needsCorrection = false
        
        // Проверяем и ограничиваем по X
        if position.x < minX {
            position.x = minX
            // Применяем силу отталкивания от левой границы
            body.applyImpulse(CGVector(dx: 50, dy: 0))
            body.velocity.dx = max(0, body.velocity.dx * 0.5)  // Замедляем движение к границе
            needsCorrection = true
        } else if position.x > maxX {
            position.x = maxX
            // Применяем силу отталкивания от правой границы
            body.applyImpulse(CGVector(dx: -50, dy: 0))
            body.velocity.dx = min(0, body.velocity.dx * 0.5)  // Замедляем движение к границе
            needsCorrection = true
        }
        
        // Проверяем и ограничиваем по Y
        if position.y < minY {
            position.y = minY
            // Применяем силу отталкивания от нижней границы
            body.applyImpulse(CGVector(dx: 0, dy: 50))
            body.velocity.dy = max(0, body.velocity.dy * 0.5)  // Замедляем движение к границе
            needsCorrection = true
        } else if position.y > maxY {
            position.y = maxY
            // Применяем силу отталкивания от верхней границы
            body.applyImpulse(CGVector(dx: 0, dy: -50))
            body.velocity.dy = min(0, body.velocity.dy * 0.5)  // Замедляем движение к границе
            needsCorrection = true
        }
        
        // Применяем ограниченную позицию, если нужно
        if needsCorrection {
            spaceship.position = position
        }
    }
    
    private func updateCamera(deltaTime: TimeInterval) {
        // Камера следует за кораблём
        let worldScale = GameConfig.Level4.worldScale
        let scaledShipPos = CGPoint(
            x: spaceship.position.x / worldScale,
            y: spaceship.position.y / worldScale
        )
        
        // Желаемая позиция с учётом ограничений по высоте
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let minY = halfHeight / worldScale
        let targetX = scaledShipPos.x
        let targetY = max(minY, scaledShipPos.y)
        
        // Экспоненциальное сглаживание без рывков
        let sharpness = GameConfig.Level4.cameraFollowSharpness
        let interpolation = CGFloat(1 - exp(-sharpness * deltaTime))
        worldCamera.position.x += (targetX - worldCamera.position.x) * interpolation
        worldCamera.position.y += (targetY - worldCamera.position.y) * interpolation
        
        // Ограничиваем камеру границами мира
        let worldWidth = size.width * worldScale
        worldCamera.position.x = max(halfWidth / worldScale, min(worldCamera.position.x, worldWidth / worldScale - halfWidth / worldScale))
        worldCamera.position.y = max(minY, worldCamera.position.y)
    }
    
    private func updateWind(deltaTime: TimeInterval) {
        windTimer -= deltaTime
        if windTimer <= 0 {
            targetWindForce = CGFloat.random(in: GameConfig.Level4.windForceRange)
            windTimer = Double.random(in: GameConfig.Level4.windChangeInterval)
        }
        let smoothingSpeed: CGFloat = 3.0
        let smoothingFactor = CGFloat(min(1.0, smoothingSpeed * deltaTime))
        smoothedWindForce += (targetWindForce - smoothedWindForce) * smoothingFactor
        windForce = smoothedWindForce
        statusLabel.text = String(format: "Ветер: %+.0f", windForce)
        wrapLabel(statusLabel, maxWidth: statusLabel.preferredMaxLayoutWidth)
        // Применяем силу ветра с множителем сноса
        let windDrift = windForce * GameConfig.Level4.windDriftMultiplier
        spaceship.physicsBody?.applyForce(CGVector(dx: windDrift, dy: 0))
    }
    
    private func applyControls(deltaTime: TimeInterval) {
        guard let body = spaceship.physicsBody else { return }
        if fuel <= 0 {
            if isMainThrustActive || isLeftThrustActive || isRightThrustActive {
                isMainThrustActive = false
                isLeftThrustActive = false
                isRightThrustActive = false
                flameNode.isHidden = true
                SoundManager.shared.stopEngineLoop()
            }
            return
        }
        
        var fuelSpent: CGFloat = 0
        let angle = normalizeAngle(spaceship.zRotation)
        
        if isMainThrustActive {
            let force = CGVector(dx: sin(angle) * GameConfig.Level4.mainThrust,
                                 dy: cos(angle) * GameConfig.Level4.mainThrust)
            body.applyForce(force)
            fuelSpent += GameConfig.Level4.fuelConsumptionPerSecond * CGFloat(deltaTime)
        }
        
        if isLeftThrustActive {
            fuelSpent += applySideThrust(direction: -1, angle: angle, body: body, deltaTime: deltaTime)
        }
        
        if isRightThrustActive {
            fuelSpent += applySideThrust(direction: 1, angle: angle, body: body, deltaTime: deltaTime)
        }
        
        // Автостабилизация корпуса
        let angleError = angle
        let stabilizationTorque = -angleError * GameConfig.Level4.autoStabilizationStrength
            - body.angularVelocity * GameConfig.Level4.autoStabilizationDamping
        let clampedTorque = max(-5.0, min(5.0, stabilizationTorque))
        body.applyTorque(clampedTorque)
        
        fuel = max(0, fuel - fuelSpent)
    }

    private func applySideThrust(direction: CGFloat, angle: CGFloat, body: SKPhysicsBody, deltaTime: TimeInterval) -> CGFloat {
        let magnitude = GameConfig.Level4.sideThrust
        let lateralAngle = angle + direction * (.pi / 2)
        let force = CGVector(dx: sin(lateralAngle) * magnitude,
                             dy: cos(lateralAngle) * magnitude)
        body.applyForce(force)
        body.applyTorque(-direction * GameConfig.Level4.sideTorque)
        return GameConfig.Level4.fuelConsumptionPerSecond * GameConfig.Level4.sideFuelConsumptionMultiplier * CGFloat(deltaTime)
    }
    
    private func extendGearIfNeeded() {
        let altitude = currentAltitude()
        if altitude < GameConfig.Level4.gearDeployHeight && !gearExtended {
            gearExtended = true
            let animation = SKAction.scaleY(to: 1.0, duration: GameConfig.Level4.gearDeployDuration)
            animation.timingMode = .easeOut
            leftGear.run(animation)
            rightGear?.run(animation)
        }
    }
    
    private func currentAltitude() -> CGFloat {
        let ground = groundHeight(at: spaceship.position.x)
        return spaceship.position.y - ground
    }
    
    private func groundHeight(at x: CGFloat) -> CGFloat {
        guard let first = terrainPoints.first, let last = terrainPoints.last else { return 0 }
        let clampedX = max(first.x, min(x, last.x))
        for idx in 0..<(terrainPoints.count - 1) {
            let p1 = terrainPoints[idx]
            let p2 = terrainPoints[idx + 1]
            if clampedX >= p1.x && clampedX <= p2.x {
                let t = (clampedX - p1.x) / (p2.x - p1.x)
                return p1.y + (p2.y - p1.y) * t
            }
        }
        return last.y
    }

    private func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var value = angle
        while value > .pi { value -= (.pi * 2) }
        while value < -.pi { value += (.pi * 2) }
        return value
    }

    // MARK: - Physics
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        let categories = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]
        if categories.contains(GameConfig.PhysicsCategory.player) && categories.contains(GameConfig.PhysicsCategory.pipe) {
            evaluateLanding()
        }
    }
    
    private func evaluateLanding() {
        guard let body = spaceship.physicsBody else { return }
        let verticalSpeed = abs(body.velocity.dy)
        let horizontalSpeed = abs(body.velocity.dx)
        let angle = abs(normalizeAngle(spaceship.zRotation))
        let inSafeZone = safeZoneRange.contains(spaceship.position.x)
        
        if verticalSpeed <= GameConfig.Level4.landingVelocityThreshold &&
            horizontalSpeed <= GameConfig.Level4.landingHorizontalThreshold &&
            angle <= GameConfig.Level4.landingAngleThreshold &&
            inSafeZone {
            handleSuccessfulLanding(verticalSpeed: verticalSpeed, horizontalSpeed: horizontalSpeed)
        } else {
            handleCrash()
        }
    }
    
    private func handleSuccessfulLanding(verticalSpeed: CGFloat, horizontalSpeed: CGFloat) {
        guard !hasLanded else { return }
        hasLanded = true
        isGameOver = true
        
        // Останавливаем звук двигателя
        SoundManager.shared.stopEngineLoop()
        
        spaceship.physicsBody?.velocity = .zero
        spaceship.physicsBody?.angularVelocity = 0
        spaceship.physicsBody?.isDynamic = false
        flameNode.isHidden = true
        statusLabel.text = "ПОСАДКА УСПЕШНА"
        
        let timeBonus = max(0, 200 - Int(elapsedTime * 18))
        let fuelBonus = Int(fuel * 4)
        let stabilityBonus = Int(max(0, GameConfig.Level4.landingVelocityThreshold - verticalSpeed))
        landingScore = max(100, timeBonus + fuelBonus + stabilityBonus)
        
        if !isAIMode {
            GameData.shared.updateHighScore(landingScore, isAIMode: false)
            GameData.shared.updateLevelRecord(level: 4, score: landingScore, isAIMode: false)
            GameData.shared.currentLevel = max(GameData.shared.currentLevel, 5)
        }
        
        showSuccessOverlay(verticalSpeed: verticalSpeed, horizontalSpeed: horizontalSpeed)
    }
    
    private func handleCrash() {
        guard !isGameOver else { return }
        isGameOver = true
        
        // Останавливаем звук двигателя
        SoundManager.shared.stopEngineLoop()
        
        // Звук взрыва и смерти
        SoundManager.shared.playSound(.explosion, on: self)
        SoundManager.shared.playSound(.die, on: self)
        
        explodeSpaceship()
        statusLabel.text = "ПОСАДКА НЕУДАЧНА"
        showFailureOverlay()
    }
    
    private func explodeSpaceship() {
        let explosion = ParticleEmitter.createExplosion(at: spaceship.position, color: theme.skPrimary, count: 45)
        for particle in explosion { addChild(particle) }
        
        let pieceCount = 10
        for i in 0..<pieceCount {
            let angle = CGFloat(i) * (.pi * 2) / CGFloat(pieceCount)
            let shard = SKShapeNode(rectOf: CGSize(width: 18, height: 26))
            shard.fillColor = theme.skPrimary
            shard.strokeColor = theme.skAccent
            shard.lineWidth = 2
            shard.glowWidth = 4
            shard.position = spaceship.position
            shard.zRotation = angle
            shard.isAntialiased = false
            addChild(shard)
            let velocity = CGVector(dx: cos(angle) * CGFloat.random(in: 14...24),
                                    dy: sin(angle) * CGFloat.random(in: 14...24))
            let animation = SKAction.customAction(withDuration: 1.0) { node, time in
                node.position.x += velocity.dx
                node.position.y += velocity.dy - time * 9
                node.zRotation += 0.5
                node.alpha = 1.0 - time
            }
            shard.run(SKAction.sequence([animation, .removeFromParent()]))
        }
        spaceship.removeFromParent()
    }
    
    // MARK: - Overlays
    private func showSuccessOverlay(verticalSpeed: CGFloat, horizontalSpeed: CGFloat) {
        setControlsVisible(false)
        let vertical = Int(verticalSpeed.rounded())
        let horizontal = Int(horizontalSpeed.rounded())
        let fuelUnits = Int(max(0, fuel.rounded()))
        let fuelPercent = Int(max(0, min(100, (fuel / GameConfig.Level4.fuelCapacity) * 100)).rounded())
        let timeSeconds = Int(elapsedTime.rounded())
        
        let message = """
        Капсула закрепилась в посадочном кармане.
        - V↓ \(vertical) | V→ \(horizontal)
        - Топливо \(fuelUnits) ед. (\(fuelPercent)%)
        - Время \(timeSeconds) с | Очки \(landingScore)
        
        Центр докладывает: пилот спасён, можно перепройти ради рекорда или продолжить кампанию.
        """
        
        let buttons = [
            OverlayButtonConfig(title: "↻ Перезапуск", name: "replay"),
            OverlayButtonConfig(title: "► Следующий этап", name: "next"),
            OverlayButtonConfig(title: "◄ Меню", name: "menu")
        ]
        
        OverlayFactory.presentModal(on: worldCamera,
                                    scene: self,
                                    theme: theme,
                                    title: "ПОСАДКА УСПЕХ",
                                    message: message,
                                    buttons: buttons,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }
    
    private func showFailureOverlay() {
        setControlsVisible(false)
        let message = StoryManager.shared.randomPostmortem()
        let buttons = [
            OverlayButtonConfig(title: "↻ ЗАНОВО", name: "retry"),
            OverlayButtonConfig(title: "◄ МЕНЮ", name: "menu")
        ]
        OverlayFactory.presentModal(on: worldCamera,
                                    scene: self,
                                    theme: theme,
                                    message: message,
                                    buttons: buttons,
                                    wrapLabel: { [weak self] label, width in
                                        self?.wrapLabel(label, maxWidth: width)
                                    })
    }
    
    private func handleOverlayTap(at location: CGPoint) {
        let nodes = self.nodes(at: location)
        for node in nodes {
            guard let name = node.name else { continue }
            switch name {
            case "retry":
                let nextSize = view?.bounds.size ?? size
                let scene = Level4Scene(size: nextSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                return
            case "replay":
                let scene = Level4Scene(size: size)
                scene.scaleMode = scaleMode
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                return
            case "menu":
                let menuSize = view?.bounds.size ?? size
                let scene = MenuScene(size: menuSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                return
            case "next":
                StoryManager.shared.presentPostLevelCutscene(from: self, level: 4, victory: true)
                return
            default:
                break
            }
        }
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
    
    // MARK: - Simple AI
    private func runAI(deltaTime: TimeInterval, currentTime: TimeInterval) {
        guard let body = spaceship.physicsBody else { return }
        let altitude = currentAltitude()
        let verticalSpeed = body.velocity.dy
        let horizontalSpeed = body.velocity.dx
        
        if currentTime - lastAITouchTime > GameConfig.Level4.aiTouchCooldown {
            lastAITouchTime = currentTime
            // Basic autopilot: stabilise horizontal drift and manage descent
            isLeftThrustActive = horizontalSpeed < -20
            isRightThrustActive = horizontalSpeed > 20
            
            if altitude > 250 {
                isMainThrustActive = verticalSpeed < -60
            } else {
                isMainThrustActive = verticalSpeed < -40
            }
            flameNode.isHidden = !isMainThrustActive
        }
    }
}

    