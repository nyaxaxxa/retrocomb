//
//  DesignSystem.swift
//  retrocomb
//
//  Centralised styling helpers aligned with Apple Design guidelines.
//

import SpriteKit
import UIKit

enum DesignTextStyle {
    case largeTitle
    case title
    case subtitle
    case body
    case footnote
    case button
}

struct DesignSystem {
    
    // Оптимизированные отступы для лучшей адаптивности на разных устройствах
    static let layoutHorizontalPadding: CGFloat = 24
    static let layoutVerticalPadding: CGFloat = 20
    static let layoutInterItemSpacing: CGFloat = 18
    static let maxReadableWidth: CGFloat = 520
    // Оптимизированный размер кнопки для лучшей читаемости и удобства нажатия
    static let buttonSize = CGSize(width: 320, height: 64)  // Базовый размер, используйте adaptiveButtonSize для адаптивности
    static let buttonContentInset: CGFloat = 24
    static let cardCornerRadius: CGFloat = 20
    static let overlayOpacity: CGFloat = 0.85
    
    /// Оптимизированная минимальная ширина кнопки для маленьких экранов
    static let minButtonWidthSmall: CGFloat = 240
    static let minButtonWidthLarge: CGFloat = 260
    
    /// Адаптивный размер кнопки, учитывающий размер экрана и safeAreaInsets
    /// Оптимизирован для лучшей читаемости и удобства использования на всех устройствах
    static func adaptiveButtonSize(for scene: SKScene) -> CGSize {
        let insets = scene.view?.safeAreaInsets ?? .zero
        let availableWidth = scene.size.width - insets.left - insets.right - layoutHorizontalPadding * 2
        // Адаптивная минимальная ширина: оптимизирована для разных размеров экранов
        let minButtonWidth: CGFloat = availableWidth < 350 ? minButtonWidthSmall : minButtonWidthLarge
        let maxButtonWidth = min(buttonSize.width, max(minButtonWidth, availableWidth * 0.9))
        let buttonWidth = max(minButtonWidth, maxButtonWidth)
        return CGSize(width: buttonWidth, height: buttonSize.height)
    }
    
    private static func scaledFontSize(baseSize: CGFloat, textStyle: UIFont.TextStyle) -> CGFloat {
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let scaledValue = metrics.scaledValue(for: baseSize)
        return min(max(14, scaledValue), baseSize * 1.35)
    }
    
    private static func configuration(for style: DesignTextStyle) -> (base: CGFloat, textStyle: UIFont.TextStyle, fontName: String) {
        switch style {
        case .largeTitle:
            return (base: 46, textStyle: .largeTitle, fontName: "Courier-Bold")
        case .title:
            return (base: 34, textStyle: .title1, fontName: "Courier-Bold")
        case .subtitle:
            return (base: 24, textStyle: .title3, fontName: "Courier")
        case .body:
            return (base: 20, textStyle: .body, fontName: "Courier")
        case .footnote:
            return (base: 16, textStyle: .footnote, fontName: "Courier")
        case .button:
            return (base: 24, textStyle: .headline, fontName: "Courier-Bold")
        }
    }
    
    private static func color(for style: DesignTextStyle, theme: ColorTheme) -> SKColor {
        switch style {
        case .largeTitle, .title, .button:
            return theme.skPrimary
        case .subtitle:
            return theme.skAccent
        case .body:
            return theme.skText
        case .footnote:
            return theme.skSecondary
        }
    }
    
    static func font(for style: DesignTextStyle) -> UIFont {
        let config = configuration(for: style)
        let size = scaledFontSize(baseSize: config.base, textStyle: config.textStyle)
        if let font = UIFont(name: config.fontName, size: size) {
            return font
        }
        let weight: UIFont.Weight = config.fontName.lowercased().contains("bold") ? .bold : .regular
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    static func apply(_ label: SKLabelNode,
                      style: DesignTextStyle,
                      theme: ColorTheme,
                      alignment: SKLabelHorizontalAlignmentMode = .center) {
        let uiFont = font(for: style)
        label.fontName = uiFont.fontName
        label.fontSize = uiFont.pointSize
        label.fontColor = color(for: style, theme: theme)
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .center
    }
    
    static func readableContentWidth(for scene: SKScene, extraMargin: CGFloat = 0) -> CGFloat {
        let insets = scene.view?.safeAreaInsets ?? .zero
        let availableWidth = scene.size.width - insets.left - insets.right - extraMargin
        let paddedWidth = availableWidth - layoutHorizontalPadding * 2
        return min(maxReadableWidth, max(160, paddedWidth))
    }
    
    static func fit(_ label: SKLabelNode, maxWidth: CGFloat, minFontSize: CGFloat = 12) {
        guard maxWidth > 0 else { return }
        var currentSize = label.fontSize
        while label.frame.width > maxWidth && currentSize > minFontSize {
            currentSize -= 1
            label.fontSize = currentSize
        }
    }
}


