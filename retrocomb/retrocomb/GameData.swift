//
//  GameData.swift
//  retrocomb
//
//  Space Flappy Game - Data Persistence
//

import Foundation

class GameData {
    static let shared = GameData()
    
    private var defaults: UserDefaults
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    @discardableResult
    func withTemporaryDefaults<T>(_ defaults: UserDefaults, perform block: () throws -> T) rethrows -> T {
        let original = self.defaults
        self.defaults = defaults
        defer { self.defaults = original }
        return try block()
    }
    
    // Keys
    private let highScoreKey = "highScore"
    private let coinsKey = "totalCoins"
    private let currentLevelKey = "currentLevel"
    private let currentThemeKey = "currentTheme"
    private let currentDifficultyKey = "currentDifficulty"
    private let leaderboardKey = "leaderboard"
    private let level1RecordKey = "level1Record"
    private let level2RecordKey = "level2Record"
    private let level3RecordKey = "level3Record"
    private let level4RecordKey = "level4Record"
    private let level5RecordKey = "level5Record"
    private let level6RecordKey = "level6Record"
    
    // Current game state
    var highScore: Int {
        get { defaults.integer(forKey: highScoreKey) }
        set { defaults.set(newValue, forKey: highScoreKey) }
    }
    
    var totalCoins: Int {
        get { defaults.integer(forKey: coinsKey) }
        set { defaults.set(newValue, forKey: coinsKey) }
    }
    
    var currentLevel: Int {
        get { defaults.integer(forKey: currentLevelKey) }
        set { defaults.set(newValue, forKey: currentLevelKey) }
    }
    
    var currentThemeIndex: Int {
        get { defaults.integer(forKey: currentThemeKey) }
        set { defaults.set(newValue, forKey: currentThemeKey) }
    }
    
    var currentDifficulty: Int {
        get { 
            let value = defaults.integer(forKey: currentDifficultyKey)
            return value == 0 && !defaults.bool(forKey: "hasSetDifficulty") ? 2 : value // Default to Normal
        }
        set { 
            defaults.set(newValue, forKey: currentDifficultyKey)
            defaults.set(true, forKey: "hasSetDifficulty")
        }
    }
    
    var level1Record: Int {
        get { defaults.integer(forKey: level1RecordKey) }
        set { defaults.set(newValue, forKey: level1RecordKey) }
    }
    
    var level2Record: Int {
        get { defaults.integer(forKey: level2RecordKey) }
        set { defaults.set(newValue, forKey: level2RecordKey) }
    }
    
    var level3Record: Int {
        get { defaults.integer(forKey: level3RecordKey) }
        set { defaults.set(newValue, forKey: level3RecordKey) }
    }
    
    var level4Record: Int {
        get { defaults.integer(forKey: level4RecordKey) }
        set { defaults.set(newValue, forKey: level4RecordKey) }
    }
    
    var level5Record: Int {
        get { defaults.integer(forKey: level5RecordKey) }
        set { defaults.set(newValue, forKey: level5RecordKey) }
    }
    
    var level6Record: Int {
        get { defaults.integer(forKey: level6RecordKey) }
        set { defaults.set(newValue, forKey: level6RecordKey) }
    }
    
    // Leaderboard entry
    struct LeaderboardEntry: Codable {
        let name: String
        let score: Int
        let level: Int
        let date: Date
    }
    
    // Leaderboard
    var leaderboard: [LeaderboardEntry] {
        get {
            guard let data = defaults.data(forKey: leaderboardKey),
                  let entries = try? JSONDecoder().decode([LeaderboardEntry].self, from: data) else {
                return []
            }
            return entries
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: leaderboardKey)
            }
        }
    }
    
    // Add entry to leaderboard
    func addLeaderboardEntry(name: String, score: Int, level: Int) {
        var entries = leaderboard
        let newEntry = LeaderboardEntry(name: name, score: score, level: level, date: Date())
        entries.append(newEntry)
        
        // Sort by score descending and keep top 10
        entries.sort { $0.score > $1.score }
        if entries.count > 10 {
            entries = Array(entries.prefix(10))
        }
        
        leaderboard = entries
        
        // Принудительно синхронизируем UserDefaults для немедленного сохранения
        defaults.synchronize()
    }
    
    // Update high score (НЕ в AI режиме)
    func updateHighScore(_ score: Int, isAIMode: Bool = false) {
        if !isAIMode && score > highScore {
            highScore = score
        }
    }
    
    // Update level record (НЕ в AI режиме)
    func updateLevelRecord(level: Int, score: Int, isAIMode: Bool = false) {
        // НЕ записываем рекорды в AI режиме!
        if isAIMode { return }
        
        switch level {
        case 1:
            if score > level1Record {
                level1Record = score
            }
        case 2:
            if score > level2Record {
                level2Record = score
            }
        case 3:
            if score > level3Record {
                level3Record = score
            }
        case 4:
            if score > level4Record {
                level4Record = score
            }
        case 5:
            if score > level5Record {
                level5Record = score
            }
        case 6:
            if score > level6Record {
                level6Record = score
            }
        default:
            break
        }
    }
    
    // Reset all data
    func resetAllData() {
        highScore = 0
        totalCoins = 0
        currentLevel = 1
        level1Record = 0
        level2Record = 0
        level3Record = 0
        level4Record = 0
        level5Record = 0
        level6Record = 0
        leaderboard = []
    }
    
    // Get current theme
    func getCurrentTheme() -> ColorTheme {
        let index = currentThemeIndex
        if index >= 0 && index < ColorTheme.allThemes.count {
            return ColorTheme.allThemes[index]
        }
        return ColorTheme.classicGreen
    }
    
    // Get current difficulty
    func getCurrentDifficulty() -> GameConfig.Difficulty {
        return GameConfig.Difficulty(rawValue: currentDifficulty) ?? .normal
    }
}

