//
//  RetroEffects.swift
//  retrocomb
//
//  ULTRA MODERN RETRO EFFECTS
//

import SpriteKit

class RetroEffects {
    
    // SCANLINES EFFECT - эффект старых CRT мониторов
    static func createScanlines(size: CGSize, color: SKColor) -> SKNode {
        let container = SKNode()
        container.name = "scanlines"
        container.alpha = 0.15
        container.zPosition = 1000
        
        let lineSpacing: CGFloat = 4
        var y: CGFloat = 0
        
        while y < size.height {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 2))
            line.fillColor = color
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width/2, y: y)
            container.addChild(line)
            y += lineSpacing
        }
        
        return container
    }
    
    // PIXEL GRID - пиксельная сетка для ретро вида
    static func createPixelGrid(size: CGSize, theme: ColorTheme) -> SKNode {
        let container = SKNode()
        container.name = "pixelGrid"
        container.alpha = 0.05
        container.zPosition = 999
        
        let gridSize: CGFloat = 8
        
        // Вертикальные линии
        var x: CGFloat = 0
        while x < size.width {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            line.path = path
            line.strokeColor = theme.skPrimary
            line.lineWidth = 1
            container.addChild(line)
            x += gridSize
        }
        
        // Горизонтальные линии
        var y: CGFloat = 0
        while y < size.height {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            line.path = path
            line.strokeColor = theme.skPrimary
            line.lineWidth = 1
            container.addChild(line)
            y += gridSize
        }
        
        return container
    }
    
    // PIXEL SHIP - пиксельный корабль для Level 1
    static func createPixelShip(size: CGSize, theme: ColorTheme) -> CGPath {
        let path = CGMutablePath()
        let pixelSize: CGFloat = 4
        
        // Рисуем корабль пиксель за пикселем (упрощённая форма)
        // Нос корабля
        path.addRect(CGRect(x: size.width/2 - pixelSize, y: 0, width: pixelSize*2, height: pixelSize))
        path.addRect(CGRect(x: size.width/2 - pixelSize*2, y: pixelSize, width: pixelSize*4, height: pixelSize))
        
        // Корпус
        path.addRect(CGRect(x: -size.width/2, y: -pixelSize, width: size.width, height: pixelSize*2))
        
        // Крылья
        path.addRect(CGRect(x: -size.width/2 - pixelSize*2, y: -size.height/2, width: pixelSize*2, height: pixelSize*3))
        path.addRect(CGRect(x: -size.width/2 - pixelSize*2, y: size.height/2 - pixelSize*3, width: pixelSize*2, height: pixelSize*3))
        
        // Двигатель
        path.addRect(CGRect(x: -size.width/2 - pixelSize, y: -pixelSize, width: pixelSize, height: pixelSize*2))
        
        return path
    }
    
    // GLITCH EFFECT - эффект глитча
    static func applyGlitchEffect(to node: SKNode, duration: TimeInterval = 0.1) {
        let originalPosition = node.position
        
        let glitch1 = SKAction.move(to: CGPoint(x: originalPosition.x + CGFloat.random(in: -3...3), 
                                                  y: originalPosition.y), duration: 0.03)
        let glitch2 = SKAction.move(to: CGPoint(x: originalPosition.x - CGFloat.random(in: -3...3), 
                                                  y: originalPosition.y), duration: 0.03)
        let restore = SKAction.move(to: originalPosition, duration: 0.04)
        
        let sequence = SKAction.sequence([glitch1, glitch2, restore])
        node.run(sequence)
    }
    
    // NEON TRAIL - неоновый след
    static func createNeonTrail(from position: CGPoint, color: SKColor, size: CGFloat = 8) -> SKShapeNode {
        let trail = SKShapeNode(circleOfRadius: size)
        trail.fillColor = color
        trail.strokeColor = .clear
        trail.glowWidth = size * 1.5
        trail.position = position
        trail.alpha = 0.8
        trail.zPosition = -1
        
        // Fade out and grow
        let grow = SKAction.scale(to: 2.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        trail.run(SKAction.sequence([SKAction.group([grow, fade]), remove]))
        
        return trail
    }
    
    // CHROMATIC ABERRATION - эффект хроматической аберрации
    static func addChromaticAberration(to node: SKNode, theme: ColorTheme) {
        // Создаём цветовые смещения
        let redShift = node.copy() as! SKNode
        redShift.alpha = 0.3
        redShift.position = CGPoint(x: node.position.x + 2, y: node.position.y)
        redShift.zPosition = node.zPosition - 1
        
        let blueShift = node.copy() as! SKNode
        blueShift.alpha = 0.3
        blueShift.position = CGPoint(x: node.position.x - 2, y: node.position.y)
        blueShift.zPosition = node.zPosition - 1
        
        if let parent = node.parent {
            parent.addChild(redShift)
            parent.addChild(blueShift)
        }
    }
    
    // VHS NOISE - эффект VHS помех
    static func createVHSNoise(size: CGSize) -> SKSpriteNode {
        let noise = SKSpriteNode(color: .white, size: size)
        noise.alpha = 0.02
        noise.zPosition = 998
        noise.blendMode = .add
        
        // Анимация мерцания
        let flicker = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.05, duration: 0.1),
            SKAction.fadeAlpha(to: 0.01, duration: 0.1)
        ])
        noise.run(SKAction.repeatForever(flicker))
        
        return noise
    }
    
    // PIXEL FONT EFFECT - стилизация текста под пиксельный
    static func stylePixelText(label: SKLabelNode, theme: ColorTheme) {
        label.fontName = "Courier-Bold"  // Моноширинный шрифт
        
        // Добавляем обводку для пиксельного эффекта
        let outline = label.copy() as! SKLabelNode
        outline.fontColor = theme.skBackground
        outline.position = CGPoint(x: 2, y: -2)
        outline.zPosition = label.zPosition - 1
        label.addChild(outline)
        
        // Неоновое свечение
        label.fontColor = theme.skPrimary
        
        // Добавляем shadow node
        let shadow = label.copy() as! SKLabelNode
        shadow.fontColor = theme.skAccent
        shadow.alpha = 0.3
        shadow.position = CGPoint(x: 1, y: -1)
        shadow.zPosition = label.zPosition - 2
        label.addChild(shadow)
    }
}

// EXTENSION для применения эффектов к существующим нодам
extension SKScene {
    func addRetroEffects(theme: ColorTheme) {
        // Scanlines
        let scanlines = RetroEffects.createScanlines(size: size, color: theme.skPrimary)
        scanlines.position = CGPoint(x: 0, y: 0)
        addChild(scanlines)
        
        // VHS Noise
        let noise = RetroEffects.createVHSNoise(size: size)
        noise.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(noise)
    }
}

