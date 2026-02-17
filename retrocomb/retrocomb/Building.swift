//
//  Building.swift
//  retrocomb
//
//  Tower Defense Buildings - Level 5
//

import SpriteKit

// Base building class
class Building: SKNode {
    var gridX: Int
    var gridY: Int
    var buildingType: GameConfig.BuildingType
    var health: Int
    var maxHealth: Int
    var visualNode: SKShapeNode!
    var theme: ColorTheme
    private var healthBarBackground: SKShapeNode?
    private var healthBarFill: SKSpriteNode?
    
    init(gridX: Int, gridY: Int, type: GameConfig.BuildingType, theme: ColorTheme) {
        self.gridX = gridX
        self.gridY = gridY
        self.buildingType = type
        self.theme = theme
        self.maxHealth = type.maxHealth
        self.health = type.maxHealth
        
        super.init()
        
        let gridSize = GameConfig.Level5.gridSize
        self.position = CGPoint(
            x: CGFloat(gridX) * gridSize + gridSize/2,
            y: CGFloat(gridY) * gridSize + gridSize/2
        )
        self.name = "building_\(type.rawValue)"
        
        createVisuals()
        configureHealthBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    private func createVisuals() {
        let gridSize = GameConfig.Level5.gridSize
        
        switch buildingType {
        case .tower:
            visualNode = createTowerVisuals(size: gridSize)
        case .wall:
            visualNode = createWallVisuals(size: gridSize)
        case .generator:
            visualNode = createGeneratorVisuals(size: gridSize)
        case .mine:
            visualNode = createMineVisuals(size: gridSize)
        }
        
        addChild(visualNode)
    }
    
    func configureHealthBar(width: CGFloat? = nil, yOffset: CGFloat? = nil) {
        let gridSize = GameConfig.Level5.gridSize
        let barWidth = width ?? gridSize * 0.8
        let barHeight: CGFloat = 6
        let offset = yOffset ?? (gridSize / 2 + 8)
        
        let background = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2)
        background.fillColor = theme.skBackground.withAlphaComponent(0.5)
        background.strokeColor = theme.skPrimary.withAlphaComponent(0.6)
        background.lineWidth = 1
        background.position = CGPoint(x: 0, y: offset)
        background.zPosition = 30
        background.isAntialiased = false
        addChild(background)
        
        let fillSize = CGSize(width: barWidth - 2, height: barHeight - 2)
        let fill = SKSpriteNode(color: theme.skAccent, size: fillSize)
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -barWidth / 2 + 1, y: offset)
        fill.zPosition = 31
        addChild(fill)
        
        healthBarBackground = background
        healthBarFill = fill
        updateHealthBar()
    }
    
    private func updateHealthBar() {
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
    
    // TOWER - Турель в стиле Dune 2
    private func createTowerVisuals(size: CGFloat) -> SKShapeNode {
        let container = SKShapeNode()
        
        // Основание (массивное)
        let base = SKShapeNode(rectOf: CGSize(width: size * 0.85, height: size * 0.85))
        base.fillColor = SKColor(red: 0.30, green: 0.24, blue: 0.18, alpha: 1.0)
        base.strokeColor = theme.skAccent
        base.lineWidth = 3
        base.glowWidth = 4
        base.isAntialiased = false
        container.addChild(base)
        
        // Внутренняя рамка
        let frame = SKShapeNode(rectOf: CGSize(width: size * 0.65, height: size * 0.65))
        frame.fillColor = .clear
        frame.strokeColor = theme.skPrimary.withAlphaComponent(0.6)
        frame.lineWidth = 1
        frame.isAntialiased = false
        container.addChild(frame)
        
        // Ствол турели (вращающийся)
        let barrel = SKShapeNode(rectOf: CGSize(width: size * 0.35, height: size * 0.55))
        barrel.fillColor = theme.skPrimary
        barrel.strokeColor = theme.skAccent
        barrel.lineWidth = 2
        barrel.position = CGPoint(x: size * 0.18, y: 0)
        barrel.isAntialiased = false
        container.addChild(barrel)
        
        // Индикатор (точка прицела)
        let indicator = SKShapeNode(rectOf: CGSize(width: size * 0.15, height: size * 0.15))
        indicator.fillColor = theme.skAccent
        indicator.strokeColor = .clear
        indicator.position = CGPoint(x: -size * 0.25, y: 0)
        indicator.isAntialiased = false
        container.addChild(indicator)
        
        return container
    }
    
    // WALL - Защитная стена (Dune 2)
    private func createWallVisuals(size: CGFloat) -> SKShapeNode {
        let container = SKShapeNode()
        
        // Бетонный блок
        let wall = SKShapeNode(rectOf: CGSize(width: size, height: size))
        wall.fillColor = SKColor(red: 0.40, green: 0.35, blue: 0.28, alpha: 1.0)
        wall.strokeColor = theme.skPrimary
        wall.lineWidth = 3
        wall.isAntialiased = false
        container.addChild(wall)
        
        // Рельефные линии
        for i in 0..<3 {
            let y = -size / 2 + size / 4 + CGFloat(i) * size / 3
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size/2 + 4, y: y))
            path.addLine(to: CGPoint(x: size/2 - 4, y: y))
            line.path = path
            line.strokeColor = theme.skAccent.withAlphaComponent(0.3)
            line.lineWidth = 2
            line.isAntialiased = false
            container.addChild(line)
        }
        
        return container
    }
    
    // GENERATOR - Генератор (Dune 2 стиль)
    private func createGeneratorVisuals(size: CGFloat) -> SKShapeNode {
        let container = SKShapeNode()
        
        // Корпус генератора
        let base = SKShapeNode(rectOf: CGSize(width: size * 0.9, height: size * 0.9))
        base.fillColor = SKColor(red: 0.20, green: 0.28, blue: 0.35, alpha: 1.0)
        base.strokeColor = theme.skAccent
        base.lineWidth = 2
        base.glowWidth = 6
        base.isAntialiased = false
        container.addChild(base)
        
        // Ядро энергии
        let core = SKShapeNode(rectOf: CGSize(width: size * 0.4, height: size * 0.4))
        core.fillColor = theme.skAccent.withAlphaComponent(0.8)
        core.strokeColor = theme.skPrimary
        core.lineWidth = 2
        core.isAntialiased = false
        container.addChild(core)
        
        // Символ
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = buildingType.symbol
        label.fontSize = size * 0.6
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: -size * 0.18)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        // Энергетическая пульсация
        let pulse = SKAction.sequence([
            SKAction.customAction(withDuration: 1.0) { node, time in
                core.alpha = 0.6 + sin(time * 6) * 0.3
            },
            SKAction.wait(forDuration: 0.0)
        ])
        container.run(SKAction.repeatForever(pulse))
        
        return container
    }
    
    // MINE - Шахта (Dune 2 - добыча специй)
    private func createMineVisuals(size: CGFloat) -> SKShapeNode {
        let container = SKShapeNode()
        
        // Корпус шахты
        let base = SKShapeNode(rectOf: CGSize(width: size * 0.88, height: size * 0.88))
        base.fillColor = SKColor(red: 0.35, green: 0.30, blue: 0.20, alpha: 1.0)
        base.strokeColor = theme.skSecondary
        base.lineWidth = 3
        base.isAntialiased = false
        container.addChild(base)
        
        // Добывающий механизм (крест)
        let cross1 = SKShapeNode(rectOf: CGSize(width: size * 0.6, height: size * 0.12))
        cross1.fillColor = theme.skPrimary
        cross1.strokeColor = .clear
        cross1.isAntialiased = false
        container.addChild(cross1)
        
        let cross2 = SKShapeNode(rectOf: CGSize(width: size * 0.12, height: size * 0.6))
        cross2.fillColor = theme.skPrimary
        cross2.strokeColor = .clear
        cross2.isAntialiased = false
        container.addChild(cross2)
        
        // Символ ресурса
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = buildingType.symbol
        label.fontSize = size * 0.5
        label.fontColor = theme.skAccent
        label.position = CGPoint(x: 0, y: -size * 0.16)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        return container
    }
    
    func takeDamage(_ damage: Int) {
        health -= damage
        
        // Visual feedback
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        visualNode.run(flash)
        updateHealthBar()
        
        if health <= 0 {
            destroy()
        }
    }
    
    func destroy() {
        // Explosion
        let explosion = ParticleEmitter.createExplosion(at: position, color: theme.skPrimary, count: 25)
        if let parent = self.parent {
            for particle in explosion {
                parent.addChild(particle)
            }
        }
        healthBarBackground?.removeFromParent()
        healthBarFill?.removeFromParent()
        removeFromParent()
    }
}

// Tower - стреляющая турель
class Tower: Building {
    var lastShotTime: TimeInterval = 0
    var shotCooldown: TimeInterval = 0.8
    var range: CGFloat = 260
    var damage: Int = 35
    
    func update(currentTime: TimeInterval, enemies: [TowerDefenseEnemy]) {
        // Ищем ближайшего врага
        guard currentTime - lastShotTime >= shotCooldown else { return }
        
        var nearestEnemy: TowerDefenseEnemy?
        var minDistance: CGFloat = .infinity
        
        for enemy in enemies where enemy.isAlive {
            let distance = hypot(enemy.position.x - position.x, enemy.position.y - position.y)
            if distance < range && distance < minDistance {
                minDistance = distance
                nearestEnemy = enemy
            }
        }
        
        if let target = nearestEnemy {
            shoot(at: target)
            lastShotTime = currentTime
        }
    }
    
    private func shoot(at enemy: TowerDefenseEnemy) {
        // Звук выстрела турели
        SoundManager.shared.playSound(.shoot, on: self)
        
        // Создаём пулю
        let bullet = SKShapeNode(circleOfRadius: 4)
        bullet.fillColor = theme.skAccent
        bullet.strokeColor = theme.skPrimary
        bullet.lineWidth = 2
        bullet.glowWidth = 4
        bullet.position = position
        bullet.name = "bullet"
        bullet.isAntialiased = false
        
        if let parent = self.parent {
            parent.addChild(bullet)
            
            // Анимация полёта к врагу
            let distance = hypot(enemy.position.x - position.x, enemy.position.y - position.y)
            let duration = TimeInterval(distance / 400)  // Скорость пули
            
            let move = SKAction.move(to: enemy.position, duration: duration)
            let remove = SKAction.removeFromParent()
            bullet.run(SKAction.sequence([move, remove]))
            
            // Урон врагу после полёта
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                enemy.takeDamage(self.damage, theme: self.theme)
            }
        }
        
        // Вращение турели в сторону врага
        let angle = atan2(enemy.position.y - position.y, enemy.position.x - position.x)
        visualNode.zRotation = angle
    }
}

// Base - главная база которую нужно защищать
class Base: Building {
    init(gridX: Int, gridY: Int, theme: ColorTheme) {
        super.init(gridX: gridX, gridY: gridY, type: .wall, theme: theme)
        
        self.maxHealth = GameConfig.Level5.baseHealth
        self.health = maxHealth
        self.name = "base"
        
        visualNode.removeFromParent()
        visualNode = createBaseVisuals()
        addChild(visualNode)
        configureHealthBar(width: GameConfig.Level5.gridSize * 1.6, yOffset: GameConfig.Level5.gridSize + 12)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    private func createBaseVisuals() -> SKShapeNode {
        let container = SKShapeNode()
        let size = GameConfig.Level5.gridSize * 2  // База 2x2 клетки
        
        // DUNE 2 стиль - массивная база с углами
        let mainBuilding = SKShapeNode(rectOf: CGSize(width: size, height: size))
        mainBuilding.fillColor = SKColor(red: 0.25, green: 0.20, blue: 0.15, alpha: 1.0)
        mainBuilding.strokeColor = theme.skAccent
        mainBuilding.lineWidth = 4
        mainBuilding.glowWidth = 8
        mainBuilding.isAntialiased = false
        container.addChild(mainBuilding)
        
        // Внутренняя рамка
        let innerFrame = SKShapeNode(rectOf: CGSize(width: size * 0.8, height: size * 0.8))
        innerFrame.fillColor = .clear
        innerFrame.strokeColor = theme.skPrimary.withAlphaComponent(0.5)
        innerFrame.lineWidth = 2
        innerFrame.isAntialiased = false
        container.addChild(innerFrame)
        
        // Центральная антенна
        let antenna = SKShapeNode(rectOf: CGSize(width: size * 0.15, height: size * 0.5))
        antenna.fillColor = theme.skAccent
        antenna.strokeColor = theme.skPrimary
        antenna.lineWidth = 2
        antenna.position = CGPoint(x: 0, y: size * 0.55)
        antenna.isAntialiased = false
        container.addChild(antenna)
        
        // Символ базы (как в Dune 2)
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = "⬢"  // Гексагон
        label.fontSize = size * 0.45
        label.fontColor = theme.skAccent
        label.position = CGPoint(x: 0, y: -size * 0.12)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        // Пульсация свечения
        let pulse = SKAction.sequence([
            SKAction.customAction(withDuration: 1.5) { node, time in
                if let shape = node as? SKShapeNode {
                    shape.glowWidth = 8 + sin(time * 2) * 3
                }
            },
            SKAction.wait(forDuration: 0.0)
        ])
        mainBuilding.run(SKAction.repeatForever(pulse))
        
        return container
    }
}

