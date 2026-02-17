//
//  Pipe.swift
//  retrocomb
//
//  Space Flappy Game - Obstacles (Pipes, Debris, Asteroids)
//

import SpriteKit

enum PipeType: Int, CaseIterable {
    case rectangle
    case lshape
    case tshape
    case cross
    case zigzag
}

class Pipe: SKNode {
    var isScored = false
    private let theme: ColorTheme
    private let pipeType: PipeType
    
    init(x: CGFloat, gapY: CGFloat, gapSize: CGFloat, theme: ColorTheme) {
        self.theme = theme
        self.pipeType = PipeType.allCases.randomElement()!
        
        super.init()
        
        self.position = CGPoint(x: x, y: 0)
        self.name = "pipe"
        
        // Create top and bottom pipes
        createPipes(gapY: gapY, gapSize: gapSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createPipes(gapY: CGFloat, gapSize: CGFloat) {
        let screenHeight = GameConfig.screenHeight
        let pipeWidth = GameConfig.Level1.pipeWidth
        
        // Top pipe
        let topHeight = screenHeight - gapY - gapSize / 2
        let topPipe = createDebris(width: pipeWidth, height: topHeight, isTop: true)
        topPipe.position = CGPoint(x: 0, y: gapY + gapSize / 2 + topHeight / 2)
        addChild(topPipe)
        
        // Bottom pipe
        let bottomHeight = gapY - gapSize / 2
        let bottomPipe = createDebris(width: pipeWidth, height: bottomHeight, isTop: false)
        bottomPipe.position = CGPoint(x: 0, y: bottomHeight / 2)
        addChild(bottomPipe)
    }
    
    private func createDebris(width: CGFloat, height: CGFloat, isTop: Bool) -> SKNode {
        let container = SKNode()
        
        switch pipeType {
        case .rectangle:
            let debris = createRectangleDebris(width: width, height: height)
            container.addChild(debris)
            
        case .lshape:
            let debris = createLShapeDebris(width: width, height: height)
            container.addChild(debris)
            
        case .tshape:
            let debris = createTShapeDebris(width: width, height: height)
            container.addChild(debris)
            
        case .cross:
            let debris = createCrossDebris(width: width, height: height)
            container.addChild(debris)
            
        case .zigzag:
            let debris = createZigzagDebris(width: width, height: height)
            container.addChild(debris)
        }
        
        // Add physics body
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
        physicsBody.categoryBitMask = GameConfig.PhysicsCategory.pipe
        physicsBody.contactTestBitMask = GameConfig.PhysicsCategory.player
        physicsBody.collisionBitMask = GameConfig.PhysicsCategory.none
        physicsBody.isDynamic = false
        container.physicsBody = physicsBody
        
        return container
    }
    
    private func createRectangleDebris(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let rect = SKShapeNode(rectOf: CGSize(width: width, height: height))
        rect.fillColor = theme.skPrimary
        rect.strokeColor = theme.skPrimary
        rect.lineWidth = 2
        rect.glowWidth = 2
        
        // Add some detail lines
        for i in stride(from: -height/2, to: height/2, by: 20) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -width/2, y: i))
            path.addLine(to: CGPoint(x: width/2, y: i))
            line.path = path
            line.strokeColor = theme.skSecondary
            line.lineWidth = 1
            rect.addChild(line)
        }
        
        return rect
    }
    
    private func createLShapeDebris(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width/2, y: -height/2))
        path.addLine(to: CGPoint(x: -width/2, y: height/2))
        path.addLine(to: CGPoint(x: width/4, y: height/2))
        path.addLine(to: CGPoint(x: width/4, y: 0))
        path.addLine(to: CGPoint(x: width/2, y: 0))
        path.addLine(to: CGPoint(x: width/2, y: -height/2))
        path.closeSubpath()
        
        let shape = SKShapeNode(path: path)
        shape.fillColor = theme.skPrimary
        shape.strokeColor = theme.skPrimary
        shape.lineWidth = 2
        shape.glowWidth = 2
        
        return shape
    }
    
    private func createTShapeDebris(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width/2, y: height/2))
        path.addLine(to: CGPoint(x: width/2, y: height/2))
        path.addLine(to: CGPoint(x: width/2, y: height/4))
        path.addLine(to: CGPoint(x: width/8, y: height/4))
        path.addLine(to: CGPoint(x: width/8, y: -height/2))
        path.addLine(to: CGPoint(x: -width/8, y: -height/2))
        path.addLine(to: CGPoint(x: -width/8, y: height/4))
        path.addLine(to: CGPoint(x: -width/2, y: height/4))
        path.closeSubpath()
        
        let shape = SKShapeNode(path: path)
        shape.fillColor = theme.skPrimary
        shape.strokeColor = theme.skPrimary
        shape.lineWidth = 2
        shape.glowWidth = 2
        
        return shape
    }
    
    private func createCrossDebris(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let container = SKShapeNode()
        
        // Horizontal bar
        let hBar = SKShapeNode(rectOf: CGSize(width: width, height: height/4))
        hBar.fillColor = theme.skPrimary
        hBar.strokeColor = theme.skPrimary
        hBar.lineWidth = 2
        container.addChild(hBar)
        
        // Vertical bar
        let vBar = SKShapeNode(rectOf: CGSize(width: width/4, height: height))
        vBar.fillColor = theme.skPrimary
        vBar.strokeColor = theme.skPrimary
        vBar.lineWidth = 2
        container.addChild(vBar)
        
        container.glowWidth = 2
        
        return container
    }
    
    private func createZigzagDebris(width: CGFloat, height: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let segments = 8
        let segmentHeight = height / CGFloat(segments)
        
        path.move(to: CGPoint(x: -width/2, y: -height/2))
        
        for i in 0..<segments {
            let y = -height/2 + segmentHeight * CGFloat(i + 1)
            let x = i % 2 == 0 ? width/2 : -width/2
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width/2 - width/4, y: height/2))
        path.addLine(to: CGPoint(x: width/2 - width/4, y: -height/2))
        path.closeSubpath()
        
        let shape = SKShapeNode(path: path)
        shape.fillColor = theme.skPrimary
        shape.strokeColor = theme.skPrimary
        shape.lineWidth = 2
        shape.glowWidth = 2
        
        return shape
    }
}

// Asteroid for Level 2
class Asteroid: SKShapeNode {
    init(x: CGFloat, theme: ColorTheme) {
        super.init()
        
        let size = CGFloat.random(in: 30...60)
        let sides = Int.random(in: 5...8)
        
        // Create irregular polygon
        let path = Asteroid.createPolygonPath(sides: sides, radius: size)
        self.path = path
        self.fillColor = theme.skPrimary
        self.strokeColor = theme.skPrimary
        self.lineWidth = 2
        self.glowWidth = 2
        
        self.position = CGPoint(x: x, y: GameConfig.screenHeight + size)
        self.name = "asteroid"
        
        // Physics
        self.physicsBody = SKPhysicsBody(circleOfRadius: size * 0.8)
        self.physicsBody?.categoryBitMask = GameConfig.PhysicsCategory.asteroid
        self.physicsBody?.contactTestBitMask = GameConfig.PhysicsCategory.player
        self.physicsBody?.collisionBitMask = GameConfig.PhysicsCategory.none
        self.physicsBody?.isDynamic = false
        
        // Rotation animation
        let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 2.0)
        self.run(SKAction.repeatForever(rotate))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func createPolygonPath(sides: Int, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angleIncrement = (2 * CGFloat.pi) / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = angleIncrement * CGFloat(i)
            let radiusVariation = radius * CGFloat.random(in: 0.8...1.2)
            let x = radiusVariation * cos(angle)
            let y = radiusVariation * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}
