//
//  ColorTheme.swift
//  retrocomb
//
//  Space Flappy Game - Color Themes
//

import UIKit
import SpriteKit

struct ColorTheme {
    let name: String
    let primary: UIColor
    let secondary: UIColor
    let background: UIColor
    let text: UIColor
    let accent: UIColor  // Новый акцентный цвет
    
    // Predefined themes - ULTRA MODERN NEON RETRO
    static let classicGreen = ColorTheme(
        name: "🟢 MATRIX",
        primary: UIColor(red: 0/255, green: 255/255, blue: 65/255, alpha: 1),    // Яркий неоновый зелёный
        secondary: UIColor(red: 50/255, green: 255/255, blue: 0/255, alpha: 1),   // Лаймовый
        background: UIColor(red: 0/255, green: 8/255, blue: 0/255, alpha: 1),     // Почти чёрный
        text: UIColor(red: 0/255, green: 255/255, blue: 65/255, alpha: 1),
        accent: UIColor(red: 150/255, green: 255/255, blue: 0/255, alpha: 1)      // Яркий акцент
    )
    
    static let cyberCyan = ColorTheme(
        name: "🔵 CYBERPUNK",
        primary: UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1),    // Электрик циан
        secondary: UIColor(red: 100/255, green: 200/255, blue: 255/255, alpha: 1), // Небесный
        background: UIColor(red: 5/255, green: 0/255, blue: 20/255, alpha: 1),    // Глубокий синий
        text: UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1),
        accent: UIColor(red: 255/255, green: 0/255, blue: 200/255, alpha: 1)      // Розовый акцент
    )
    
    static let neonMagenta = ColorTheme(
        name: "🟣 SYNTHWAVE",
        primary: UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1),    // Неон пурпур
        secondary: UIColor(red: 255/255, green: 100/255, blue: 255/255, alpha: 1), // Розовый
        background: UIColor(red: 20/255, green: 0/255, blue: 30/255, alpha: 1),   // Фиолетовый чёрный
        text: UIColor(red: 255/255, green: 50/255, blue: 255/255, alpha: 1),
        accent: UIColor(red: 255/255, green: 200/255, blue: 0/255, alpha: 1)      // Золотой акцент
    )
    
    static let fireOrange = ColorTheme(
        name: "🔴 OUTRUN",
        primary: UIColor(red: 255/255, green: 60/255, blue: 0/255, alpha: 1),     // Огненный
        secondary: UIColor(red: 255/255, green: 180/255, blue: 0/255, alpha: 1),  // Янтарный
        background: UIColor(red: 20/255, green: 5/255, blue: 0/255, alpha: 1),    // Тёмно-оранжевый
        text: UIColor(red: 255/255, green: 100/255, blue: 0/255, alpha: 1),
        accent: UIColor(red: 255/255, green: 0/255, blue: 150/255, alpha: 1)      // Розовый акцент
    )
    
    static let retroWhite = ColorTheme(
        name: "⚪ VAPORWAVE",
        primary: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1),  // Чистый белый
        secondary: UIColor(red: 150/255, green: 220/255, blue: 255/255, alpha: 1), // Пастельный голубой
        background: UIColor(red: 10/255, green: 10/255, blue: 15/255, alpha: 1),  // Почти чёрный
        text: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1),
        accent: UIColor(red: 255/255, green: 100/255, blue: 200/255, alpha: 1)    // Розовый акцент
    )
    
    static let allThemes = [classicGreen, cyberCyan, neonMagenta, fireOrange, retroWhite]
    
    // Convert UIColor to SKColor for SpriteKit compatibility
    var skPrimary: SKColor { SKColor(cgColor: primary.cgColor) }
    var skSecondary: SKColor { SKColor(cgColor: secondary.cgColor) }
    var skBackground: SKColor { SKColor(cgColor: background.cgColor) }
    var skText: SKColor { SKColor(cgColor: text.cgColor) }
    var skAccent: SKColor { SKColor(cgColor: accent.cgColor) }
}

// PIXEL ART HELPER для ретро эффектов
extension SKShapeNode {
    func applyPixelatedStyle() {
        // Убираем сглаживание для пиксельного вида
        self.isAntialiased = false
        self.lineWidth = 2
    }
    
    func applyNeonGlow(color: SKColor, intensity: CGFloat = 5) {
        self.glowWidth = intensity
        self.strokeColor = color
        
        // Добавляем пульсацию свечения
        let glowUp = SKAction.customAction(withDuration: 0.8) { node, time in
            if let shape = node as? SKShapeNode {
                shape.glowWidth = intensity + sin(time * 3) * 2
            }
        }
        self.run(SKAction.repeatForever(glowUp))
    }
}

