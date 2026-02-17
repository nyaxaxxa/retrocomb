//
//  OverlayFactory.swift
//  retrocomb
//
//  Унифицированное построение модальных оверлеев (постмортемы, подсказки и т.д.)
//

import SpriteKit

struct OverlayButtonConfig {
    let title: String
    let name: String
}

enum OverlayFactory {
    
    static func presentModal(on parent: SKNode,
                             scene: SKScene,
                             theme: ColorTheme,
                             title: String? = nil,
                             message: String,
                             buttons: [OverlayButtonConfig],
                             baseZPosition: CGFloat = 300,
                             extraWidthMargin: CGFloat = -20,
                             wrapLabel: (SKLabelNode, CGFloat) -> Void) {
        
        let safeInsets = scene.view?.safeAreaInsets ?? .zero
        let safeCornersInScene: [CGPoint]
        if let view = scene.view {
            let left = safeInsets.left
            let right = view.bounds.width - safeInsets.right
            let top = safeInsets.top
            let bottom = view.bounds.height - safeInsets.bottom
            safeCornersInScene = [
                scene.convertPoint(fromView: CGPoint(x: left, y: top)),
                scene.convertPoint(fromView: CGPoint(x: right, y: top)),
                scene.convertPoint(fromView: CGPoint(x: left, y: bottom)),
                scene.convertPoint(fromView: CGPoint(x: right, y: bottom))
            ]
        } else {
            safeCornersInScene = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: scene.size.width, y: 0),
                CGPoint(x: 0, y: scene.size.height),
                CGPoint(x: scene.size.width, y: scene.size.height)
            ]
        }
        
        let minX = safeCornersInScene.map { $0.x }.min() ?? scene.size.width / 2
        let maxX = safeCornersInScene.map { $0.x }.max() ?? scene.size.width / 2
        let minY = safeCornersInScene.map { $0.y }.min() ?? scene.size.height / 2
        let maxY = safeCornersInScene.map { $0.y }.max() ?? scene.size.height / 2
        let safeWidth = max(160, maxX - minX)
        let safeHeight = max(160, maxY - minY)
        let anchorInScene = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let anchorPoint: CGPoint = {
            guard parent !== scene else { return anchorInScene }
            return parent.convert(anchorInScene, from: scene)
        }()
        
        let dimSize = CGSize(width: max(scene.size.width, safeWidth),
                             height: max(scene.size.height, safeHeight))
        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.82), size: dimSize)
        dim.name = "modal_dim"
        dim.zPosition = baseZPosition
        dim.position = anchorPoint
        dim.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        dim.isUserInteractionEnabled = false
        parent.addChild(dim)
        
        let desiredWidth = DesignSystem.readableContentWidth(for: scene, extraMargin: extraWidthMargin)
        let safeContentWidth = max(160, safeWidth - DesignSystem.layoutHorizontalPadding * 2)
        let readableWidth = min(desiredWidth, safeContentWidth)
        let horizontalPadding = DesignSystem.layoutHorizontalPadding
        let verticalPadding = DesignSystem.layoutVerticalPadding
        let spacing = DesignSystem.layoutInterItemSpacing
        
        let messageLabel = SKLabelNode(fontNamed: "Courier")
        DesignSystem.apply(messageLabel, style: .body, theme: theme)
        messageLabel.fontColor = theme.skSecondary
        messageLabel.text = message
        messageLabel.preferredMaxLayoutWidth = readableWidth
        wrapLabel(messageLabel, readableWidth)
        messageLabel.verticalAlignmentMode = .center
        messageLabel.horizontalAlignmentMode = .center
        let messageHeight = messageLabel.frame.height
        
        var titleNode: SKLabelNode?
        var titleHeight: CGFloat = 0
        if let title {
            let label = SKLabelNode(fontNamed: "Courier-Bold")
            label.text = title
            DesignSystem.apply(label, style: .title, theme: theme)
            label.fontColor = theme.skAccent
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            titleHeight = label.frame.height
            titleNode = label
        }
        
        let buttonSpacing = CGFloat(max(0, buttons.count - 1)) * spacing
        let contentSpacingAfterMessage = buttons.isEmpty ? 0 : spacing
        let titleSpacing = titleNode == nil ? 0 : spacing
        
        let safeHeightLimit = max(220, safeHeight - DesignSystem.layoutVerticalPadding * 2)
        var buttonHeight = DesignSystem.buttonSize.height
        var buttonsTotalHeight = CGFloat(buttons.count) * buttonHeight
        var requiredHeight = verticalPadding * 2
            + titleHeight
            + titleSpacing
            + messageHeight
            + contentSpacingAfterMessage
            + buttonsTotalHeight
            + buttonSpacing
        
        if buttons.count > 0 {
            let availableForButtons = safeHeightLimit
                - verticalPadding * 2
                - titleHeight
                - titleSpacing
                - messageHeight
                - contentSpacingAfterMessage
                - buttonSpacing
            if availableForButtons > 0 {
                let maxButtonHeight = availableForButtons / CGFloat(buttons.count)
                if maxButtonHeight < buttonHeight {
                    buttonHeight = max(44, maxButtonHeight)
                    buttonsTotalHeight = CGFloat(buttons.count) * buttonHeight
                    requiredHeight = verticalPadding * 2
                        + titleHeight
                        + titleSpacing
                        + messageHeight
                        + contentSpacingAfterMessage
                        + buttonsTotalHeight
                        + buttonSpacing
                }
            } else {
                buttonHeight = 44
                buttonsTotalHeight = CGFloat(buttons.count) * buttonHeight
                requiredHeight = verticalPadding * 2
                    + titleHeight
                    + titleSpacing
                    + messageHeight
                    + contentSpacingAfterMessage
                    + buttonsTotalHeight
                    + buttonSpacing
            }
        }
        
        let cardHeight = min(max(requiredHeight, 220), safeHeightLimit)
        let cardWidth = readableWidth + horizontalPadding * 2
        
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight),
                               cornerRadius: DesignSystem.cardCornerRadius)
        card.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: DesignSystem.overlayOpacity)
        card.strokeColor = theme.skPrimary.withAlphaComponent(0.4)
        card.lineWidth = 4
        card.glowWidth = 8
        card.position = anchorPoint
        card.zPosition = baseZPosition + 1
        card.name = "modal_card"
        parent.addChild(card)
        
        let gridSize = CGSize(width: cardWidth * 0.96, height: cardHeight * 0.94)
        let grid = RetroEffects.createPixelGrid(size: gridSize, theme: theme)
        grid.alpha = 0.12
        grid.position = CGPoint(x: -gridSize.width / 2, y: -gridSize.height / 2)
        grid.zPosition = -1
        card.addChild(grid)
        
        var cursor = cardHeight / 2 - verticalPadding
        
        if let titleNode {
            titleNode.position = CGPoint(x: 0, y: cursor - titleHeight / 2)
            titleNode.zPosition = baseZPosition + 2
            card.addChild(titleNode)
            cursor -= titleHeight
            cursor -= spacing
        }
        
        messageLabel.position = CGPoint(x: 0, y: cursor - messageHeight / 2)
        messageLabel.zPosition = baseZPosition + 2
        card.addChild(messageLabel)
        cursor -= messageHeight
        
        if !buttons.isEmpty {
            cursor -= spacing
        }
        
        let buttonWidth = min(DesignSystem.buttonSize.width, readableWidth)
        
        for (index, config) in buttons.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight),
                                     cornerRadius: DesignSystem.cardCornerRadius)
            button.fillColor = theme.skAccent.withAlphaComponent(0.22)
            button.strokeColor = theme.skPrimary
            button.lineWidth = 3.5
            button.glowWidth = 6
            button.position = CGPoint(x: 0, y: cursor - buttonHeight / 2)
            button.zPosition = baseZPosition + 2
            button.name = config.name
            button.isAntialiased = false

            let label = SKLabelNode(fontNamed: "Courier-Bold")
            label.text = config.title
            DesignSystem.apply(label, style: .button, theme: theme)
            label.fontSize = min(label.fontSize, buttonHeight * 0.48)
            label.fontColor = theme.skPrimary
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = .zero
            label.zPosition = baseZPosition + 3
            label.name = config.name
            button.addChild(label)

            let halo = SKShapeNode(rectOf: CGSize(width: buttonWidth * 1.05, height: buttonHeight * 1.08),
                                   cornerRadius: DesignSystem.cardCornerRadius * 1.05)
            halo.strokeColor = theme.skAccent.withAlphaComponent(0.35)
            halo.lineWidth = 1.5
            halo.fillColor = .clear
            halo.zPosition = baseZPosition + 1.5
            button.addChild(halo)

            card.addChild(button)

            cursor -= buttonHeight
            cursor -= spacing
        }
    }
}


