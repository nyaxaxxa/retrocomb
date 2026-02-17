//
//  CutsceneScene.swift
//  retrocomb
//
//  Simple tap-through narrative scene with neon styling.
//

import SpriteKit
import UIKit

final class CutsceneScene: SKScene {
    
    private let descriptor: CutsceneDescriptor
    private let nextSceneProvider: () -> SKScene?
    
    private var currentIndex: Int = -1
    private var lines: [String] { descriptor.lines }
    
    private var titleLabel: SKLabelNode!
    private var textContainer: SKNode!
    private var promptLabel: SKLabelNode!
    private var backgroundNode: SKShapeNode!
    
    private var safeInsets: UIEdgeInsets = .zero
    private var theme: ColorTheme = .classicGreen
    
    init(size: CGSize, descriptor: CutsceneDescriptor, nextSceneProvider: @escaping () -> SKScene?) {
        self.descriptor = descriptor
        self.nextSceneProvider = nextSceneProvider
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("init(coder:) is not supported for runtime-instantiated nodes")
        return nil
    }
    
    override func didMove(to view: SKView) {
        safeInsets = view.safeAreaInsets
        theme = GameData.shared.getCurrentTheme()
        backgroundColor = theme.skBackground
        buildBackground()
        buildTitle()
        buildTextContainer()
        advance()
    }
    
    private func buildBackground() {
        let usableWidth = maxContentWidth()
        let usableHeight = size.height - safeInsets.top - safeInsets.bottom - 160
        backgroundNode = SKShapeNode(
            rectOf: CGSize(width: usableWidth, height: usableHeight),
            cornerRadius: DesignSystem.cardCornerRadius
        )
        backgroundNode.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.08, alpha: DesignSystem.overlayOpacity)
        backgroundNode.strokeColor = theme.skPrimary.withAlphaComponent(0.35)
        backgroundNode.lineWidth = 4
        backgroundNode.glowWidth = 10
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(backgroundNode)
        
        let gridSize = CGSize(width: usableWidth * 0.98, height: usableHeight * 0.96)
        let grid = RetroEffects.createPixelGrid(size: gridSize, theme: theme)
        grid.alpha = 0.1
        grid.position = CGPoint(x: size.width / 2 - gridSize.width / 2, y: size.height / 2 - gridSize.height / 2)
        addChild(grid)
    }
    
    private func buildTitle() {
        titleLabel = SKLabelNode(fontNamed: "Courier-Bold")
        titleLabel.text = descriptor.title
        DesignSystem.apply(titleLabel, style: .title, theme: theme)
        titleLabel.fontColor = theme.skAccent
        titleLabel.preferredMaxLayoutWidth = maxContentWidth() - DesignSystem.buttonContentInset
        titleLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + (backgroundNode.frame.height / 2) - safeInsets.top - 50
        )
        addChild(titleLabel)
        
        promptLabel = SKLabelNode(fontNamed: "Courier")
        promptLabel.text = "Коснитесь экрана..."
        DesignSystem.apply(promptLabel, style: .footnote, theme: theme)
        promptLabel.fontColor = theme.skSecondary.withAlphaComponent(0.8)
        promptLabel.position = CGPoint(x: size.width / 2,
                                       y: size.height / 2 - (backgroundNode.frame.height / 2) + safeInsets.bottom + 40)
        addChild(promptLabel)
    }
    
    private func buildTextContainer() {
        textContainer = SKNode()
        textContainer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(textContainer)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        if tappedNodes.contains(where: { $0.name == "continueButton" }) {
            finish()
            return
        }
        advance()
    }
    
    private func advance() {
        currentIndex += 1
        if currentIndex >= lines.count {
            showContinueButton()
            return
        }
        setDisplayedText(lines[currentIndex])
    }
    
    private func setDisplayedText(_ text: String) {
        textContainer.removeAllChildren()
        let wrappedLines = wrap(text: text, maxWidth: maxContentWidth() - 60)
        let lineSpacing = DesignSystem.layoutInterItemSpacing / 2
        var labels: [SKLabelNode] = []
        for line in wrappedLines {
            let label = SKLabelNode(fontNamed: "Courier")
            label.text = line
            DesignSystem.apply(label, style: .body, theme: theme)
            label.preferredMaxLayoutWidth = maxContentWidth() - DesignSystem.buttonContentInset
            label.alpha = 0
            labels.append(label)
        }
        let totalHeight = labels.reduce(0) { $0 + $1.frame.height } +
            CGFloat(max(0, labels.count - 1)) * lineSpacing
        var currentY = totalHeight / 2
        for label in labels {
            label.position = CGPoint(x: 0, y: currentY)
            textContainer.addChild(label)
            label.run(SKAction.fadeIn(withDuration: 0.3))
            currentY -= label.frame.height + lineSpacing
        }
        promptLabel.text = currentIndex == lines.count - 1 ? "Коснитесь, чтобы выбраться..." : "Коснитесь для продолжения..."
    }
    
    private func showContinueButton() {
        textContainer.removeAllChildren()
        promptLabel.text = ""
        
        let adaptiveSize = DesignSystem.adaptiveButtonSize(for: self)
        let buttonSize = CGSize(width: min(adaptiveSize.width, maxContentWidth()), height: adaptiveSize.height)
        let button = SKShapeNode(rectOf: buttonSize, cornerRadius: DesignSystem.cardCornerRadius)
        button.fillColor = .clear
        button.strokeColor = theme.skPrimary
        button.lineWidth = 3
        button.glowWidth = 6
        button.position = CGPoint(x: 0, y: -DesignSystem.layoutInterItemSpacing)
        button.name = "continueButton"
        textContainer.addChild(button)
        
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = descriptor.returnsToMenu ? "◄ В главное меню" : "► Продолжить"
        DesignSystem.apply(label, style: .button, theme: theme)
        label.position = CGPoint(x: 0, y: 0)
        label.name = "continueButton"
        label.preferredMaxLayoutWidth = buttonSize.width - DesignSystem.buttonContentInset * 2
        button.addChild(label)
    }
    
    private func finish() {
        guard let view = view else { return }
        if let next = nextSceneProvider() {
            view.presentScene(next, transition: SKTransition.fade(withDuration: 0.6))
        } else {
            let menu = MenuScene(size: size)
            menu.scaleMode = scaleMode
            view.presentScene(menu, transition: SKTransition.fade(withDuration: 0.6))
        }
    }
    
    private func maxContentWidth() -> CGFloat {
        return DesignSystem.readableContentWidth(for: self, extraMargin: 80)
    }
    
    private func wrap(text: String, maxWidth: CGFloat) -> [String] {
        var result: [String] = []
        var currentLine = ""
        let font = DesignSystem.font(for: .body)
        for word in text.split(separator: " ") {
            let spaced = currentLine.isEmpty ? String(word) : currentLine + " " + word
            let width = (spaced as NSString).size(withAttributes: [.font: font]).width
            if width <= maxWidth {
                currentLine = spaced
            } else {
                if !currentLine.isEmpty {
                    result.append(currentLine)
                }
                currentLine = String(word)
            }
        }
        if !currentLine.isEmpty {
            result.append(currentLine)
        }
        return result
    }
}


