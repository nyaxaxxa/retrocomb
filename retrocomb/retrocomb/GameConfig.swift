//
//  GameConfig.swift
//  retrocomb
//
//  Space Flappy Game - Configuration and Constants
//

import Foundation
import CoreGraphics

class GameConfig {
    // Screen dimensions (Portrait orientation)
    static let screenWidth: CGFloat = 600
    static let screenHeight: CGFloat = 900
    
    // Level 1 - Flappy Bird style
    struct Level1 {
        static let gravity: CGFloat = -0.5  // Отрицательная - тянет вниз
        static let flapStrength: CGFloat = 8.0  // Положительная - толкает вверх
        static let playerSize = CGSize(width: 50, height: 35)
        static let pipeWidth: CGFloat = 60
        static let pipeGap: CGFloat = 180
        static let pipeSpacing: CGFloat = 300
        static let scrollSpeed: CGFloat = 3.0
        static let scoreToAdvance = 50
    }
    
    // Level 2 - Top-Down
    struct Level2 {
        static let playerSize = CGSize(width: 40, height: 50)
        static let horizontalSpeed: CGFloat = 6.0
        static let friction: CGFloat = 0.92
        static let asteroidSpeed: CGFloat = 4.0
        static let asteroidSpawnRate: CGFloat = 0.02
        static let scoreToAdvance = 25
    }
    
    // Level 3 - Open World (EXTREME MODE)
    struct Level3 {
        static let worldWidth: CGFloat = 15000   // В 10 раз больше!
        static let worldHeight: CGFloat = 20000  // В 10 раз больше!
        static let playerSize = CGSize(width: 30, height: 30)
        static let acceleration: CGFloat = 0.5  // Чуть быстрее
        static let friction: CGFloat = 0.98
        static let maxSpeed: CGFloat = 10.0  // Увеличена макс скорость
        static let enemyCount = 100  // В 5 раз больше врагов!
        static let foodCount = 500   // Больше еды в большом мире
        static let minimapSize: CGFloat = 110  // Компактная миникарта
        static let enemyBaseSpeed: CGFloat = 2.5  // Базовая скорость врагов
        static let enemyAggressionRange: CGFloat = 800  // Дальность атаки
        static let scoreToAdvance = 25  // Минимум для перехода на уровень 4
    }
    
    // Level 4 - Landing Simulator (BALLISTIC MODE)
    struct Level4 {
        static let gravity = CGVector(dx: 0, dy: -3.2)  // Увеличена гравитация для сложности
        static let airResistance: CGFloat = 0.07
        static let windDriftMultiplier: CGFloat = 2.6  // Увеличен ветер
        static let terrainSegmentWidth: CGFloat = 80
        static let safeZoneWidth: CGFloat = 85  // Ещё уже полоса посадки
        static let safeZoneTolerance: CGFloat = 12  // Строже требования
        static let landingVelocityThreshold: CGFloat = 55  // Строже требования к вертикальной скорости
        static let landingHorizontalThreshold: CGFloat = 35  // Строже требования к горизонтальной скорости
        static let landingAngleThreshold: CGFloat = (.pi / 2) * 0.03  // Строже требования к углу
        static let gearDeployHeight: CGFloat = 350
        static let gearDeployDuration: TimeInterval = 0.4
        static let mainThrust: CGFloat = 2880  // Удвоенная мощность двигателя
        static let sideThrust: CGFloat = 1320  // Удвоенная боковая мощность
        static let fuelCapacity: CGFloat = 220  // Меньше топлива
        static let fuelConsumptionPerSecond: CGFloat = 18  // Больше потребление
        static let sideFuelConsumptionMultiplier: CGFloat = 0.6  // Больше потребление при боковом движении
        static let windForceRange: ClosedRange<CGFloat> = -65...65  // Сильнее ветер
        static let windChangeInterval: ClosedRange<TimeInterval> = 1.5...3.0  // Чаще меняется ветер
        static let aiTouchCooldown: TimeInterval = 0.15
        static let sideTorque: CGFloat = 0.6
        static let autoStabilizationStrength: CGFloat = 2.2
        static let autoStabilizationDamping: CGFloat = 1.2
        static let cameraFollowSharpness: CGFloat = 4.5
        static let shipScale: CGFloat = 0.5  // Ещё меньше корабль
        static let worldScale: CGFloat = 3.0  // Втрое больше мир!
        static let initialDistanceMultiplier: CGFloat = 1.8  // Множитель для увеличения расстояния до посадки
    }
    
    // Level 5 - Tower Defense (BASE BUILDER)
    struct Level5 {
        static let gridSize: CGFloat = 40
        static let gridWidth: Int = 15
        static let gridHeight: Int = 20
        static let baseHealth = 350
        static let startingResources = 200  // Больше ресурсов для старта
        static let startingEnergy = 80
        static let minWaveInterval: TimeInterval = 1.5
        static let maxWaveInterval: TimeInterval = 3.0
        static let initialWaveDelay: TimeInterval = 2.5
        static let generatorTickValue = 5
        static let mineTickValue = 8
        static let incomeTickInterval: TimeInterval = 1.0
    }
    
    // Level 6 - Retro Doom-lite (NEON DUNGEON)
    struct Level6 {
        static let rayCount: Int = 180
        static let fieldOfView: CGFloat = .pi / 3.2
        static let playerMaxHealth: Int = 150
        static let playerMoveSpeed: CGFloat = 3.4
        static let playerStrafeSpeed: CGFloat = 2.6
        static let playerTurnSpeed: CGFloat = 2.8
        static let fireCooldown: TimeInterval = 0.22
        static let fireDamage: Int = 60
        static let hitScore: Int = 150
        static let exitBonus: Int = 600
        static let enemyBaseHealth: Int = 80
        static let enemyMoveSpeed: CGFloat = 1.35
        static let enemyDamage: Int = 16
        static let enemyAttackInterval: TimeInterval = 1.1
        static let enemyMeleeRange: CGFloat = 0.45
        static let enemyHitFOV: CGFloat = .pi / 28
        static let mapTileSize: CGFloat = 1.0
        static let ambientFloorAlpha: CGFloat = 0.12
        static let ambientCeilingAlpha: CGFloat = 0.08
        static let waveRequirementForUnlock: Int = 4
        static let finalScoreForVictory: Int = 50
    }
    
    // Building types for Level 5
    enum BuildingType: String, CaseIterable {
        case tower = "Турель"
        case wall = "Стена"
        case generator = "Генератор"
        case mine = "Шахта"
        
        var cost: Int {
            switch self {
            case .tower: return 50
            case .wall: return 20
            case .generator: return 100
            case .mine: return 80
            }
        }
        
        var description: String {
            switch self {
            case .tower: return "Стреляет во врагов"
            case .wall: return "Блокирует врагов"
            case .generator: return "+5 энергии/сек"
            case .mine: return "+10 ресурсов/сек"
            }
        }
        
        var symbol: String {
            switch self {
            case .tower: return "╬"
            case .wall: return "█"
            case .generator: return "⚡"
            case .mine: return "◆"
            }
        }
        
        var maxHealth: Int {
            switch self {
            case .tower: return 180
            case .wall: return 240
            case .generator: return 150
            case .mine: return 130
            }
        }
    }
    
    // Coins
    struct Coin {
        static let size: CGFloat = 20
        static let value = 1
        static let magnetRange: CGFloat = 100
    }
    
    // Upgrades
    enum UpgradeType: String, CaseIterable {
        case speed = "Speed Boost"
        case size = "Size Reduction"
        case shield = "Shield"
        case magnet = "Coin Magnet"
        
        var description: String {
            switch self {
            case .speed:
                return "Увеличить скорость"
            case .size:
                return "Уменьшить размер"
            case .shield:
                return "Защитный щит"
            case .magnet:
                return "Магнит для монет"
            }
        }
    }
    
    struct Upgrade {
        static let coinCost = 10
        static let speedMultiplier: CGFloat = 1.15
        static let sizeMultiplier: CGFloat = 0.85
        static let magnetMultiplier: CGFloat = 1.5
    }
    
    // Difficulty levels
    enum Difficulty: Int, CaseIterable {
        case superEasy = 0
        case easy = 1
        case normal = 2
        case hard = 3
        case extreme = 4
        case ai = 5
        
        var name: String {
            switch self {
            case .superEasy: return "Super Easy"
            case .easy: return "Easy"
            case .normal: return "Normal"
            case .hard: return "Hard"
            case .extreme: return "Extreme"
            case .ai: return "AI Mode"
            }
        }
        
        var gravityMultiplier: CGFloat {
            switch self {
            case .superEasy: return 0.6
            case .easy: return 0.8
            case .normal: return 1.0
            case .hard: return 1.3
            case .extreme: return 1.5
            case .ai: return 1.0
            }
        }
        
        var speedMultiplier: CGFloat {
            switch self {
            case .superEasy: return 0.7
            case .easy: return 0.85
            case .normal: return 1.0
            case .hard: return 1.2
            case .extreme: return 1.4
            case .ai: return 1.0
            }
        }
        
        var gapMultiplier: CGFloat {
            switch self {
            case .superEasy: return 1.5
            case .easy: return 1.2
            case .normal: return 1.0
            case .hard: return 0.85
            case .extreme: return 0.7
            case .ai: return 1.0
            }
        }
    }
    
    // Particles
    struct Particle {
        static let engineParticleCount = 3
        static let explosionParticleCount = 20
        static let particleLifetime: TimeInterval = 1.0
    }
    
    // Physics categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let player: UInt32 = 0b1
        static let pipe: UInt32 = 0b10
        static let coin: UInt32 = 0b100
        static let enemy: UInt32 = 0b1000
        static let food: UInt32 = 0b10000
        static let asteroid: UInt32 = 0b100000
        static let level6Wall: UInt32 = 0b1000000
        static let level6Enemy: UInt32 = 0b10000000
        static let level6Projectile: UInt32 = 0b100000000
        static let level6Exit: UInt32 = 0b1000000000
    }
}
