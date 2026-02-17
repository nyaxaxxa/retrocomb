//
//  WaveSystem.swift
//  retrocomb
//
//  Wave System for Tower Defense - Level 5
//

import Foundation

class WaveSystem {
    var currentWave: Int = 0
    var isWaveActive: Bool = false
    var timeUntilNextWave: TimeInterval = 0
    
    func startNextWave() -> WaveInfo {
        currentWave += 1
        isWaveActive = true
        return buildWaveInfo(for: currentWave)
    }
    
    func completeWave() {
        isWaveActive = false
        timeUntilNextWave = Double.random(in: GameConfig.Level5.minWaveInterval...GameConfig.Level5.maxWaveInterval)
    }
    
    private func buildWaveInfo(for wave: Int) -> WaveInfo {
        var availableTypes: [TowerDefenseEnemy.EnemyType] = [.scout]
        if wave >= 2 { availableTypes.append(.bruiser) }
        if wave >= 3 { availableTypes.append(.disruptor) }
        if wave >= 4 { availableTypes.append(.tank) }
        
        // Увеличено количество врагов для большей сложности
        let baseCount = 10 + wave * 4  // Было 8 + wave * 3
        var types: [TowerDefenseEnemy.EnemyType] = []
        types.reserveCapacity(baseCount)
        
        for _ in 0..<baseCount {
            if wave % 5 == 0 && !types.contains(.boss) && types.count > baseCount / 2 {
                types.append(.boss)
            } else if let type = availableTypes.randomElement() {
                types.append(type)
            }
        }
        
        if wave % 5 == 0 {
            types.append(.boss)
        }
        
        // Уменьшен интервал спавна врагов для большей интенсивности
        let spawnInterval = max(0.25, 1.0 - Double(wave) * 0.1)  // Было max(0.35, 1.2 - Double(wave) * 0.08)
        return WaveInfo(waveNumber: wave, enemyTypes: types, spawnInterval: spawnInterval)
    }
}

struct WaveInfo {
    let waveNumber: Int
    let enemyTypes: [TowerDefenseEnemy.EnemyType]
    let spawnInterval: TimeInterval
    
    var enemyCount: Int { enemyTypes.count }
    
    var description: String {
        "Волна \(waveNumber) • \(enemyCount)"
    }
}

