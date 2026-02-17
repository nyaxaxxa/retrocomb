import SpriteKit
import UIKit

class Level5Scene: SKScene {
    private var theme: ColorTheme = .classicGreen
    private var difficulty: GameConfig.Difficulty = .normal
    private var safeInsets: UIEdgeInsets = .zero
    
    // Grid
    private let gridWidth = GameConfig.Level5.gridWidth
    private let gridHeight = GameConfig.Level5.gridHeight
    private let gridSize = GameConfig.Level5.gridSize
    private var gridNode: SKNode!
    private var grid: [[Building?]] = []
    
    // Buildings
    private var buildings: [Building] = []
    private var towers: [Tower] = []
    private var base: Base!
    
    // Enemies & waves
    private var enemies: [TowerDefenseEnemy] = []
    private let waveSystem = WaveSystem()
    private var currentWaveInfo: WaveInfo?
    private var pendingEnemyTypes: [TowerDefenseEnemy.EnemyType] = []
    
    // Resources
    private var resources = GameConfig.Level5.startingResources
    private var energy = GameConfig.Level5.startingEnergy
    
    // Score tracking
    private var score = 0
    private var enemiesKilled = 0
    private var isGameOver = false
    
    // UI
    private var resourcesLabel: SKLabelNode!
    private var energyLabel: SKLabelNode!
    private var baseHealthLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!
    private var buildMenuContainer: SKNode!
    private var buildMenuButtons: [GameConfig.BuildingType: SKShapeNode] = [:]
    private var menuContentWidth: CGFloat = 0
    private var menuScrollOffset: CGFloat = 0
    private var menuBasePosition: CGPoint = .zero
    private var menuIsDragging = false
    private var menuDragStarted = false
    private var menuLastTouchX: CGFloat = 0
    private var pendingMenuSelection: GameConfig.BuildingType?
    private let menuLoopCopies = 3
    private let buildMenuHeight: CGFloat = 110
    private let buildMenuPadding: CGFloat = 20
    private var messageNode: SKLabelNode?
    
    // Build selection
    private var selectedBuildingType: GameConfig.BuildingType?
    private var ghostNode: SKShapeNode?
    private var ghostSymbol: SKLabelNode?
    
    private var lastUpdateTime: TimeInterval = 0
    private var spawnAccumulator: TimeInterval = 0
    private var incomeAccumulator: TimeInterval = 0
    private var hasTransitionedToLevel6 = false
    private var awaitingTransitionChoice = false
    private var transitionOverlay: SKNode?
    
    override func didMove(to view: SKView) {
        theme = GameData.shared.getCurrentTheme()
        difficulty = GameData.shared.getCurrentDifficulty()
        safeInsets = view.safeAreaInsets
        addRetroEffects(theme: theme)
        backgroundColor = theme.skBackground
        
        setupScene()
        setupGrid()
        setupBase()
        setupUI()
        setupBuildMenu()
        
        waveSystem.timeUntilNextWave = GameConfig.Level5.initialWaveDelay
        
        // Запускаем фоновую музыку
        SoundManager.shared.playBackgroundMusic(fileName: "retro_music.mp3")
    }
    
    // MARK: - Setup
    private func setupScene() {
        // DUNE 2 style - песчаная планета с СТАТИЧНОЙ текстурой (без мерцания!)
        let sandColor1 = SKColor(red: 0.76, green: 0.60, blue: 0.42, alpha: 1.0)
        let sandColor2 = SKColor(red: 0.65, green: 0.50, blue: 0.35, alpha: 1.0)
        
        // Статичная текстура песка
        for _ in 0..<600 {
            let pixelSize = CGFloat.random(in: 3...8)
            let pixel = SKShapeNode(rectOf: CGSize(width: pixelSize, height: pixelSize))
            pixel.fillColor = Bool.random() ? sandColor1 : sandColor2
            pixel.strokeColor = .clear
            pixel.position = CGPoint(x: CGFloat.random(in: 0...size.width), 
                                    y: CGFloat.random(in: 0...size.height))
            pixel.alpha = CGFloat.random(in: 0.3...0.7)
            pixel.zPosition = -15
            pixel.isAntialiased = false
            addChild(pixel)
            // БЕЗ анимации мерцания!
        }
        
        // Градиент неба (статичный)
        let topGradient = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height / 3))
        topGradient.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 0.4)
        topGradient.strokeColor = .clear
        topGradient.position = CGPoint(x: size.width / 2, y: size.height - size.height / 6)
        topGradient.zPosition = -14
        addChild(topGradient)
        
        // Горизонт линия
        let horizon = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
        horizon.fillColor = theme.skPrimary.withAlphaComponent(0.3)
        horizon.strokeColor = .clear
        horizon.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        horizon.zPosition = -13
        addChild(horizon)
    }
    
    private func setupGrid() {
        gridNode = SKNode()
        gridNode.position = CGPoint(
            x: (size.width - CGFloat(gridWidth) * gridSize) / 2,
            y: (size.height - CGFloat(gridHeight) * gridSize) / 2
        )
        gridNode.zPosition = 0
        addChild(gridNode)
        
        grid = Array(repeating: Array(repeating: nil, count: gridWidth), count: gridHeight)
        
        for x in 0...gridWidth {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(x) * gridSize, y: 0))
            path.addLine(to: CGPoint(x: CGFloat(x) * gridSize, y: CGFloat(gridHeight) * gridSize))
            line.path = path
            line.strokeColor = theme.skPrimary.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.isAntialiased = false
            gridNode.addChild(line)
        }
        
        for y in 0...gridHeight {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: CGFloat(y) * gridSize))
            path.addLine(to: CGPoint(x: CGFloat(gridWidth) * gridSize, y: CGFloat(gridHeight) * gridSize))
            line.path = path
            line.strokeColor = theme.skPrimary.withAlphaComponent(0.15)
            line.lineWidth = 1
            line.isAntialiased = false
            gridNode.addChild(line)
        }
    }
    
    private func setupBase() {
        // База в центре экрана (как в Dune 2)
        let baseX = gridWidth / 2 - 1
        let baseY = gridHeight / 2 - 1
        base = Base(gridX: baseX, gridY: baseY, theme: theme)
        gridNode.addChild(base)
        buildings.append(base)
        
        for dx in 0..<2 {
            for dy in 0..<2 {
                let gx = baseX + dx
                let gy = baseY + dy
                if gx < gridWidth && gy < gridHeight {
                    grid[gy][gx] = base
                }
            }
        }
    }
    
    private func setupUI() {
        // DUNE 2 стиль HUD - верхняя панель
        let hudHeight: CGFloat = 60
        let hudBackground = SKShapeNode(rectOf: CGSize(width: size.width, height: hudHeight))
        hudBackground.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.06, alpha: 0.92)
        hudBackground.strokeColor = theme.skPrimary.withAlphaComponent(0.7)
        hudBackground.lineWidth = 2
        hudBackground.position = CGPoint(x: size.width / 2, y: size.height - hudHeight / 2)
        hudBackground.zPosition = 98
        hudBackground.isAntialiased = false
        addChild(hudBackground)
        
        let topMargin = size.height - safeInsets.top - 22
        let leftX = safeInsets.left + 35
        let rightX = size.width - safeInsets.right - 35
        let centerX = size.width / 2 + (safeInsets.left - safeInsets.right) / 2
        let safeWidth = size.width - safeInsets.left - safeInsets.right - 70
        let columnWidth = max(160, safeWidth / 3)
        
        resourcesLabel = makeHUDLabel(text: "💎 \(resources)", position: CGPoint(x: leftX, y: topMargin), alignment: .left, maxWidth: columnWidth)
        energyLabel = makeHUDLabel(text: "⚡ \(energy)", position: CGPoint(x: leftX, y: topMargin - 28), alignment: .left, maxWidth: columnWidth)
        waveLabel = makeHUDLabel(text: "Волна 0", position: CGPoint(x: centerX, y: topMargin), alignment: .center, maxWidth: columnWidth)
        scoreLabel = makeHUDLabel(text: "Счёт: 0", position: CGPoint(x: centerX, y: topMargin - 28), alignment: .center, maxWidth: columnWidth)
        baseHealthLabel = makeHUDLabel(text: "База: 100%", position: CGPoint(x: rightX, y: topMargin), alignment: .right, maxWidth: columnWidth)
    }
    
    private func makeHUDLabel(text: String, position: CGPoint, alignment: SKLabelHorizontalAlignmentMode, maxWidth: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = theme.skAccent
        label.horizontalAlignmentMode = alignment
        label.position = position
        label.zPosition = 100
        label.preferredMaxLayoutWidth = maxWidth
        DesignSystem.fit(label, maxWidth: maxWidth)
        addChild(label)
        return label
    }
    
    private func refreshHUDLabel(_ label: SKLabelNode?, text: String) {
        guard let label else { return }
        label.text = text
        let maxWidth = label.preferredMaxLayoutWidth > 0 ? label.preferredMaxLayoutWidth : 160
        DesignSystem.fit(label, maxWidth: maxWidth)
    }
    
    private func setupBuildMenu() {
        let menuHeight = buildMenuHeight
        let menuY = safeInsets.bottom + menuHeight / 2 + buildMenuPadding
        buildMenuButtons.removeAll()
        menuContentWidth = 0
        menuScrollOffset = 0
        menuIsDragging = false
        menuDragStarted = false
        pendingMenuSelection = nil
        let horizontalOffset = (safeInsets.left - safeInsets.right) / 2
        let availableWidth = max(240, size.width - safeInsets.left - safeInsets.right - buildMenuPadding * 2)
        
        // Фон панели
        let menuBackground = SKShapeNode(rectOf: CGSize(width: availableWidth + buildMenuPadding * 2, height: menuHeight))
        menuBackground.fillColor = SKColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 0.95)
        menuBackground.strokeColor = theme.skPrimary.withAlphaComponent(0.8)
        menuBackground.lineWidth = 3
        menuBackground.position = CGPoint(x: size.width / 2 + horizontalOffset, y: menuY)
        menuBackground.zPosition = 85
        menuBackground.isAntialiased = false
        menuBackground.name = "menuBackground"
        addChild(menuBackground)
        
        // Декоративная линия
        let topLine = SKShapeNode(rectOf: CGSize(width: availableWidth, height: 2))
        topLine.fillColor = theme.skAccent.withAlphaComponent(0.6)
        topLine.strokeColor = .clear
        topLine.position = CGPoint(x: size.width / 2 + horizontalOffset, y: menuY + menuHeight / 2 - 10)
        topLine.zPosition = 86
        addChild(topLine)
        
        // Контейнер кнопок
        buildMenuContainer = SKNode()
        menuBasePosition = CGPoint(x: size.width / 2 + horizontalOffset, y: menuY)
        buildMenuContainer.position = menuBasePosition
        buildMenuContainer.zPosition = 90
        addChild(buildMenuContainer)
        
        let buttonHeight: CGFloat = 80
        let types = GameConfig.BuildingType.allCases
        let buttonsCount = CGFloat(types.count)
        let spacing = max(16, min(32, availableWidth * 0.05))
        let buttonWidth = max(120, min(180, (availableWidth - spacing * (buttonsCount - 1)) / buttonsCount))
        menuContentWidth = (buttonWidth + spacing) * buttonsCount
        let baseStartX = -menuContentWidth / 2 + buttonWidth / 2
        
        for loop in 0..<menuLoopCopies {
            let loopOffset = (CGFloat(loop) - CGFloat(menuLoopCopies - 1) / 2) * menuContentWidth
            for (index, type) in types.enumerated() {
                let x = baseStartX + CGFloat(index) * (buttonWidth + spacing) + loopOffset
                let button = createBuildButton(type: type,
                                               position: CGPoint(x: x, y: 0),
                                               size: CGSize(width: buttonWidth, height: buttonHeight))
                if buildMenuButtons[type] == nil {
                    buildMenuButtons[type] = button
                }
            }
        }
        
        menuScrollOffset = 0
        updateMenuScroll()
    }
    
    @discardableResult
    private func createBuildButton(type: GameConfig.BuildingType, position: CGPoint, size: CGSize) -> SKShapeNode {
        // DUNE 2 стиль кнопок - угловатые с двойной обводкой
        let button = SKShapeNode(rectOf: size, cornerRadius: 0)
        button.fillColor = SKColor(red: 0.18, green: 0.14, blue: 0.10, alpha: 0.9)
        button.strokeColor = theme.skPrimary
        button.lineWidth = 2
        button.position = position
        button.isAntialiased = false
        button.name = "build_\(type.rawValue)"
        buildMenuContainer.addChild(button)
        
        // Внутренняя рамка (Dune 2 эффект)
        let innerFrame = SKShapeNode(rectOf: CGSize(width: size.width - 8, height: size.height - 8))
        innerFrame.fillColor = .clear
        innerFrame.strokeColor = theme.skAccent.withAlphaComponent(0.4)
        innerFrame.lineWidth = 1
        innerFrame.position = .zero
        button.addChild(innerFrame)
        
        // Иконка/символ
        let symbol = SKLabelNode(fontNamed: "Courier-Bold")
        symbol.text = type.symbol
        symbol.fontSize = 36
        symbol.fontColor = theme.skAccent
        symbol.position = CGPoint(x: 0, y: 16)
        symbol.name = button.name
        button.addChild(symbol)
        
        // Название
        let nameLabel = SKLabelNode(fontNamed: "Courier-Bold")
        nameLabel.text = type.rawValue
        nameLabel.fontSize = 13
        nameLabel.fontColor = theme.skPrimary
        nameLabel.position = CGPoint(x: 0, y: -10)
        nameLabel.name = button.name
        button.addChild(nameLabel)
        
        // Стоимость
        let costLabel = SKLabelNode(fontNamed: "Courier-Bold")
        costLabel.text = "💎 \(type.cost)"
        costLabel.fontSize = 14
        costLabel.fontColor = theme.skAccent
        costLabel.position = CGPoint(x: 0, y: -28)
        costLabel.name = button.name
        button.addChild(costLabel)
        return button
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if isGameOver {
            handleOverlayTap(at: touch.location(in: self))
            return
        }
        guard !isGameOver else { return }
        let location = touch.location(in: self)
        
        let menuBoundary = safeInsets.bottom + buildMenuHeight + buildMenuPadding
        if location.y <= menuBoundary {
            menuIsDragging = true
            menuDragStarted = false
            menuLastTouchX = location.x
            pendingMenuSelection = nil
            
            let nodes = self.nodes(at: location)
            for node in nodes {
                guard let name = node.name else { continue }
                if name.hasPrefix("build_"),
                   let buildingType = GameConfig.BuildingType(rawValue: name.replacingOccurrences(of: "build_", with: "")) {
                    pendingMenuSelection = buildingType
                    break
                }
            }
            return
        }
        
        if selectedBuildingType != nil {
            updateGhost(at: location)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if menuIsDragging {
            let deltaX = location.x - menuLastTouchX
            if !menuDragStarted && abs(deltaX) > 6 {
                menuDragStarted = true
                pendingMenuSelection = nil
            }
            if menuDragStarted {
                menuScrollOffset += deltaX
                updateMenuScroll()
            }
            menuLastTouchX = location.x
            return
        }
        
        if location.y > safeInsets.bottom + buildMenuHeight + buildMenuPadding, selectedBuildingType != nil {
            updateGhost(at: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if isGameOver {
            handleOverlayTap(at: location)
            return
        }
        
        if menuIsDragging {
            if !menuDragStarted, let type = pendingMenuSelection {
                selectBuilding(type: type)
            }
            menuIsDragging = false
            menuDragStarted = false
            pendingMenuSelection = nil
            return
        }
        
        if location.y <= safeInsets.bottom + buildMenuHeight + buildMenuPadding {
            return
        }
        
        if let buildingType = selectedBuildingType {
            placeBuilding(at: location, type: buildingType)
        }
        clearGhost()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    private func selectBuilding(type: GameConfig.BuildingType) {
        guard resources >= type.cost else {
            showMessage("Недостаточно ресурсов")
            return
        }
        selectedBuildingType = type
        clearGhost()
        for button in buildMenuButtons.values {
            button.strokeColor = theme.skPrimary
            button.lineWidth = 2
        }
        if let button = buildMenuButtons[type] {
            button.strokeColor = theme.skAccent
            button.lineWidth = 4
        }
    }
    
    private func updateGhost(at location: CGPoint) {
        guard let buildingType = selectedBuildingType else { return }
        if ghostNode == nil {
            let node = SKShapeNode(rectOf: CGSize(width: gridSize, height: gridSize))
            node.fillColor = theme.skPrimary.withAlphaComponent(0.25)
            node.strokeColor = theme.skAccent
            node.lineWidth = 1.5
            node.glowWidth = 2
            node.isAntialiased = false
            node.zPosition = 40
            gridNode.addChild(node)
            ghostNode = node
            let symbol = SKLabelNode(fontNamed: "Courier-Bold")
            symbol.fontSize = 20
            symbol.fontColor = theme.skAccent
            symbol.position = CGPoint(x: 0, y: -6)
            symbol.zPosition = 41
            node.addChild(symbol)
            ghostSymbol = symbol
        }
        ghostSymbol?.text = buildingType.symbol
        let gridLocation = convert(location, to: gridNode)
        let gx = Int(gridLocation.x / gridSize)
        let gy = Int(gridLocation.y / gridSize)
        if gx >= 0 && gx < gridWidth && gy >= 0 && gy < gridHeight {
            ghostNode?.position = CGPoint(x: CGFloat(gx) * gridSize + gridSize / 2,
                                          y: CGFloat(gy) * gridSize + gridSize / 2)
            let canPlace = grid[gy][gx] == nil && resources >= buildingType.cost
            ghostNode?.fillColor = canPlace ? theme.skPrimary.withAlphaComponent(0.35) : .red.withAlphaComponent(0.25)
        } else {
            ghostNode?.fillColor = .red.withAlphaComponent(0.25)
        }
    }
    
    private func clearGhost() {
        ghostNode?.removeFromParent()
        ghostNode = nil
        ghostSymbol = nil
    }
    
    private func placeBuilding(at location: CGPoint, type: GameConfig.BuildingType) {
        let gridLocation = convert(location, to: gridNode)
        let gx = Int(gridLocation.x / gridSize)
        let gy = Int(gridLocation.y / gridSize)
        guard gx >= 0 && gx < gridWidth && gy >= 0 && gy < gridHeight else { return }
        guard grid[gy][gx] == nil else {
            showMessage("Клетка занята")
            return
        }
        guard resources >= type.cost else { return }
        
        resources -= type.cost
        refreshHUDLabel(resourcesLabel, text: "💎 \(resources)")
        
        let building: Building
        if type == .tower {
            let tower = Tower(gridX: gx, gridY: gy, type: type, theme: theme)
            towers.append(tower)
            building = tower
        } else {
            building = Building(gridX: gx, gridY: gy, type: type, theme: theme)
        }
        gridNode.addChild(building)
        buildings.append(building)
        grid[gy][gx] = building
        selectedBuildingType = nil
        for button in buildMenuButtons.values {
            button.strokeColor = theme.skPrimary
            button.lineWidth = 2
        }
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        guard !hasTransitionedToLevel6 else { return }
        let deltaTime = lastUpdateTime == 0 ? 0.016 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        updateWaves(deltaTime: deltaTime)
        updateEnemies()
        updateTowers(currentTime: currentTime)
        cleanDestroyedBuildings()
        updateIncome(deltaTime: deltaTime)
    }
    
    private func updateWaves(deltaTime: TimeInterval) {
        if !waveSystem.isWaveActive {
            waveSystem.timeUntilNextWave -= deltaTime
            if waveSystem.timeUntilNextWave <= 0 {
                startWave()
            } else {
                refreshHUDLabel(waveLabel, text: String(format: "След. волна через %.0fс", waveSystem.timeUntilNextWave))
            }
            return
        }
        guard let waveInfo = currentWaveInfo else { return }
        var spawnInterval = waveInfo.spawnInterval
        if spawnInterval <= 0 { spawnInterval = 0.4 }
        spawnAccumulator += deltaTime
        if spawnAccumulator >= spawnInterval {
            spawnAccumulator -= spawnInterval
            if !pendingEnemyTypes.isEmpty {
                let type = pendingEnemyTypes.removeFirst()
                spawnEnemy(type: type, wave: waveInfo.waveNumber)
            }
        }
        if pendingEnemyTypes.isEmpty && enemies.allSatisfy({ !$0.isAlive }) {
            completeWave()
        }
    }
    
    private func startWave() {
        currentWaveInfo = waveSystem.startNextWave()
        if let info = currentWaveInfo {
            pendingEnemyTypes = info.enemyTypes
            spawnAccumulator = 0
            refreshHUDLabel(waveLabel, text: "Волна \(info.waveNumber)")
            let flash = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15)
            ])
            waveLabel.run(SKAction.repeat(flash, count: 3))
        }
    }
    
    private func spawnEnemy(type: TowerDefenseEnemy.EnemyType, wave: Int) {
        let gridWorldWidth = CGFloat(gridWidth) * gridSize
        let gridWorldHeight = CGFloat(gridHeight) * gridSize
        let side = Int.random(in: 0...3)
        let spawnPosition: CGPoint
        switch side {
        case 0:
            spawnPosition = CGPoint(x: CGFloat.random(in: 0...gridWorldWidth), y: gridWorldHeight + 60)
        case 1:
            spawnPosition = CGPoint(x: gridWorldWidth + 60, y: CGFloat.random(in: 0...gridWorldHeight))
        case 2:
            spawnPosition = CGPoint(x: CGFloat.random(in: 0...gridWorldWidth), y: -60)
        default:
            spawnPosition = CGPoint(x: -60, y: CGFloat.random(in: 0...gridWorldHeight))
        }
        let enemy = TowerDefenseEnemy(type: type, spawnPosition: spawnPosition, targetPosition: base.position, wave: wave, theme: theme)
        enemy.onDeath = { [weak self] enemy in
            guard let self = self else { return }
            self.resources += enemy.rewardResources
            self.energy += enemy.rewardResources / 2
            self.score += enemy.scoreValue
            self.enemiesKilled += 1
            self.refreshHUD()
        }
        gridNode.addChild(enemy)
        enemies.append(enemy)
    }
    
    private func updateEnemies() {
        for enemy in enemies where enemy.isAlive {
            enemy.updateMovement()
            if enemy.hasReachedTarget() {
                base.takeDamage(enemy.damage)
                enemy.onDeath = nil
                enemy.die(theme: theme)
                if base.health <= 0 {
                    gameOver()
                    return
                }
                updateBaseHealth()
            } else {
                let gx = Int(enemy.position.x / gridSize)
                let gy = Int(enemy.position.y / gridSize)
                if gx >= 0 && gx < gridWidth && gy >= 0 && gy < gridHeight {
                    if let building = grid[gy][gx] {
                        building.takeDamage(enemy.damage)
                        if !enemy.isAlive {
                            continue
                        }
                        enemy.onDeath = nil
                        enemy.die(theme: theme)
                        if building.health <= 0 {
                            grid[gy][gx] = nil
                        }
                    }
                }
            }
        }
        enemies.removeAll { !$0.isAlive }
    }
    
    private func updateTowers(currentTime: TimeInterval) {
        for tower in towers {
            tower.update(currentTime: currentTime, enemies: enemies)
        }
    }
    
    private func cleanDestroyedBuildings() {
        buildings.removeAll { building in
            if building.parent == nil {
                if let tower = building as? Tower {
                    towers.removeAll { $0 === tower }
                }
                for y in 0..<gridHeight {
                    for x in 0..<gridWidth {
                        if grid[y][x] === building {
                            grid[y][x] = nil
                        }
                    }
                }
                return true
            }
            return false
        }
    }
    
    private func updateIncome(deltaTime: TimeInterval) {
        incomeAccumulator += deltaTime
        if incomeAccumulator >= GameConfig.Level5.incomeTickInterval {
            incomeAccumulator = 0
            for building in buildings {
                switch building.buildingType {
                case .generator:
                    energy += GameConfig.Level5.generatorTickValue
                case .mine:
                    resources += GameConfig.Level5.mineTickValue
                default:
                    continue
                }
            }
            refreshHUD()
        }
    }
    
    private func completeWave() {
        waveSystem.completeWave()
        spawnAccumulator = 0
        if let info = currentWaveInfo {
            score += info.enemyCount * 10
            resources += 40 + info.waveNumber * 8
            showMessage("Волна \(info.waveNumber) отбита")
            if info.waveNumber >= GameConfig.Level6.waveRequirementForUnlock && !awaitingTransitionChoice && !hasTransitionedToLevel6 {
                awaitingTransitionChoice = true
                isGameOver = true
                showTransitionChoiceOverlay(for: info.waveNumber)
                return
            }
        }
        refreshHUD()
    }
    
    private func refreshHUD() {
        refreshHUDLabel(resourcesLabel, text: "💎 \(resources)")
        refreshHUDLabel(energyLabel, text: "⚡ \(energy)")
        refreshHUDLabel(scoreLabel, text: "Счёт: \(score)")
        updateBaseHealth()
    }
    
    private func updateBaseHealth() {
        let percent = max(0, Int((Float(base.health) / Float(base.maxHealth)) * 100))
        refreshHUDLabel(baseHealthLabel, text: "База: \(percent)%")
        baseHealthLabel.fontColor = percent < 30 ? .red : theme.skPrimary
    }
    
    private func showMessage(_ text: String) {
        messageNode?.removeFromParent()
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        label.fontSize = 20
        label.fontColor = theme.skAccent
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 180)
        label.zPosition = 150
        label.alpha = 0
        addChild(label)
        messageNode = label
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 1.2),
            SKAction.fadeOut(withDuration: 0.4),
            .removeFromParent()
        ])
        label.run(sequence)
    }

    private func showTransitionChoiceOverlay(for wave: Int) {
        transitionOverlay?.removeFromParent()
        let container = SKNode()
        container.zPosition = 180
        let safeInsets = view?.safeAreaInsets ?? .zero
        container.position = CGPoint(
            x: size.width / 2 + (safeInsets.left - safeInsets.right) / 2,
            y: size.height / 2
        )
        addChild(container)
        transitionOverlay = container
        
        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = .black
        bg.alpha = 0.78
        bg.position = CGPoint(x: 0, y: 0)
        bg.zPosition = 0
        container.addChild(bg)
        
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "Волна \(wave) отражена"
        DesignSystem.apply(title, style: .title, theme: theme)
        title.position = CGPoint(
            x: 0,
            y: DesignSystem.buttonSize.height * 1.4
        )
        title.zPosition = 1
        container.addChild(title)
        
        let recap = SKLabelNode(fontNamed: "Courier")
        recap.text = "Можно продолжить оборону ради рекорда или отступить внутрь базы."
        DesignSystem.apply(recap, style: .body, theme: theme)
        recap.fontColor = theme.skSecondary
        recap.position = CGPoint(
            x: 0,
            y: title.position.y - (title.frame.height + DesignSystem.layoutInterItemSpacing)
        )
        recap.zPosition = 1
        recap.preferredMaxLayoutWidth = DesignSystem.readableContentWidth(for: self, extraMargin: 120)
        container.addChild(recap)
        wrapLabel(recap, maxWidth: recap.preferredMaxLayoutWidth)
        
        var buttonY = -(DesignSystem.buttonSize.height / 2 + DesignSystem.layoutVerticalPadding)
        createOverlayButton(text: "↻ Продолжить оборону",
                            position: CGPoint(x: 0, y: buttonY),
                            name: "transition_continue",
                            parent: container)
        
        buttonY -= DesignSystem.buttonSize.height + DesignSystem.layoutInterItemSpacing
        createOverlayButton(text: "► Перейти внутрь",
                            position: CGPoint(x: 0, y: buttonY),
                            name: "transition_next",
                            parent: container)
        
        buttonY -= DesignSystem.buttonSize.height + DesignSystem.layoutInterItemSpacing
        createOverlayButton(text: "◄ Меню",
                            position: CGPoint(x: 0, y: buttonY),
                            name: "transition_menu",
                            parent: container)
    }
    
    @discardableResult
    private func createOverlayButton(text: String, position: CGPoint, name: String, parent: SKNode? = nil) -> SKShapeNode {
        let buttonParent = parent ?? self
        let button = SKShapeNode(rectOf: DesignSystem.buttonSize, cornerRadius: DesignSystem.cardCornerRadius)
        button.fillColor = .clear
        button.strokeColor = theme.skPrimary
        button.lineWidth = 3
        button.glowWidth = 4
        button.position = position
        button.zPosition = 200
        button.name = name
        button.isAntialiased = false
        buttonParent.addChild(button)
        
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = text
        DesignSystem.apply(label, style: .button, theme: theme)
        label.position = CGPoint(x: 0, y: 0)
        label.name = name
        label.preferredMaxLayoutWidth = DesignSystem.buttonSize.width - DesignSystem.buttonContentInset * 2
        button.addChild(label)
        
        return button
    }
    
    private func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        GameData.shared.updateHighScore(score)
        GameData.shared.updateLevelRecord(level: 5, score: score)
        GameData.shared.currentLevel = max(GameData.shared.currentLevel, 5)
        let postmortem = StoryManager.shared.randomPostmortem()
        showTransitionBanner(text: postmortem)
        advanceToLevel6(victory: false)
    }
    
    private func showTransitionBanner(text: String) {
        let banner = SKLabelNode(fontNamed: "Courier-Bold")
        banner.text = text
        banner.fontSize = 26
        banner.fontColor = theme.skAccent
        banner.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        banner.zPosition = 250
        banner.alpha = 0
        addChild(banner)
        banner.preferredMaxLayoutWidth = safeContentWidth(margin: 100)
        wrapLabel(banner, maxWidth: banner.preferredMaxLayoutWidth)
        banner.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }
    
    private func advanceToLevel6(victory: Bool) {
        guard !hasTransitionedToLevel6 else { return }
        hasTransitionedToLevel6 = true
        isGameOver = true
        transitionOverlay?.removeFromParent()
        transitionOverlay = nil
        awaitingTransitionChoice = false
        GameData.shared.currentLevel = max(GameData.shared.currentLevel, 6)
        let delay: TimeInterval = victory ? 1.2 : 0.8
        run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                StoryManager.shared.presentPostLevelCutscene(from: self, level: 5, victory: victory)
            }
        ]))
    }
    
    private func handleOverlayTap(at location: CGPoint) {
        let nodes = nodes(at: location)
        for node in nodes {
            guard let name = node.name else { continue }
            switch name {
            case "retry":
                let nextSize = view?.bounds.size ?? size
                let scene = Level5Scene(size: nextSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                return
            case "menu":
                let menuSize = view?.bounds.size ?? size
                let scene = MenuScene(size: menuSize)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                return
            case "next":
                transitionOverlay?.removeFromParent()
                transitionOverlay = nil
                awaitingTransitionChoice = false
                StoryManager.shared.presentPostLevelCutscene(from: self, level: 5, victory: true)
                return
            case "transition_continue":
                resumeDefenseAfterChoice()
                return
            case "transition_next":
                advanceToLevel6(victory: true)
                return
            default:
                continue
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

    private func resumeDefenseAfterChoice() {
        transitionOverlay?.removeFromParent()
        transitionOverlay = nil
        awaitingTransitionChoice = false
        isGameOver = false
        waveSystem.timeUntilNextWave = GameConfig.Level5.minWaveInterval
        waveSystem.isWaveActive = false
        startWave()
    }
    
    private func safeContentWidth(margin: CGFloat) -> CGFloat {
        return DesignSystem.readableContentWidth(for: self, extraMargin: margin)
    }
    
    private func updateMenuScroll() {
        guard menuContentWidth > 0 else { return }
        let wrapLength = menuContentWidth
        if menuScrollOffset > wrapLength {
            menuScrollOffset = menuScrollOffset.truncatingRemainder(dividingBy: wrapLength)
        } else if menuScrollOffset < -wrapLength {
            menuScrollOffset = menuScrollOffset.truncatingRemainder(dividingBy: wrapLength)
        }
        buildMenuContainer.position = CGPoint(x: menuBasePosition.x + menuScrollOffset, y: menuBasePosition.y)
    }
}
