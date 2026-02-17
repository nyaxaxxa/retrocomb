//
//  SoundManager.swift
//  retrocomb
//
//  Space Flappy Game - Sound and Music Manager
//

import SpriteKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var isMusicEnabled = true  // Звуки включены по умолчанию
    private var isSoundEnabled = true  // Звуки включены по умолчанию
    
    // Кэш для активных звуковых плееров
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            // Используем .playback для более надежного воспроизведения звуков
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ SoundManager: Failed to setup audio session: \(error)")
            // Пробуем альтернативный вариант
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("⚠️ SoundManager: Failed to setup audio session with ambient category: \(error)")
            }
        }
    }
    
    // MARK: - Background Music
    
    func playBackgroundMusic(fileName: String, volume: Float = 0.4) {
        guard isMusicEnabled else { return }
        
        stopBackgroundMusic()
        
        // Генерируем простую ретро-музыку программно
        playRetroBackgroundMusic(volume: volume)
    }
    
    private func playRetroBackgroundMusic(volume: Float) {
        // Генерируем простую ретро-музыку программно
        guard let musicData = RetroSoundGenerator.generateBackgroundMusic() else {
            return
        }
        
        // Сохраняем во временный файл
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("retro_music.wav")
        
        do {
            try musicData.write(to: tempURL)
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: tempURL)
            backgroundMusicPlayer?.numberOfLoops = -1  // Бесконечный цикл
            backgroundMusicPlayer?.volume = volume
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            
            // Проверяем, что музыка действительно играет
            if backgroundMusicPlayer?.isPlaying == false {
                print("⚠️ SoundManager: Музыка не воспроизводится, пробуем еще раз...")
                backgroundMusicPlayer?.play()
            }
        } catch {
            print("⚠️ SoundManager: Ошибка воспроизведения музыки: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopBackgroundMusic()
        }
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        if !enabled {
            stopEngineLoop()
        }
    }
    
    // MARK: - Engine Loop Sound
    
    private var engineLoopPlayer: AVAudioPlayer?
    
    func startEngineLoop() {
        guard isSoundEnabled else { return }
        guard engineLoopPlayer == nil else { return }  // Уже играет
        
        guard let soundData = RetroSoundGenerator.generateEngineLoopSound() else { return }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("engine_loop.wav")
        
        do {
            try soundData.write(to: tempURL)
            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.numberOfLoops = -1  // Бесконечный цикл
            player.volume = 0.35  // Восстановленная громкость для звука двигателя
            player.prepareToPlay()
            player.play()
            engineLoopPlayer = player
        } catch {
            print("⚠️ SoundManager: Ошибка воспроизведения звука двигателя: \(error)")
        }
    }
    
    func stopEngineLoop() {
        engineLoopPlayer?.stop()
        engineLoopPlayer = nil
    }
    
    // MARK: - Sound Effects
    
    func playSound(_ soundType: SoundType, on node: SKNode? = nil) {
        guard isSoundEnabled else {
            print("⚠️ SoundManager: Звуки отключены, пропускаем \(soundType)")
            return
        }
        
        // Генерируем звук программно в стиле NES/SNES
        let generator = getSoundGenerator(for: soundType)
        guard let soundData = generator() else {
            print("⚠️ SoundManager: Не удалось сгенерировать звук \(soundType), используем fallback")
            // Если генерация не удалась, пробуем использовать файл
            fallbackToSKAction(soundType: soundType, node: node)
            return
        }
        
        // Воспроизводим через AVAudioPlayer
        do {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).wav")
            
            try soundData.write(to: tempURL)
            let player = try AVAudioPlayer(contentsOf: tempURL)
            player.prepareToPlay()
            // Восстановленная громкость звуковых эффектов
            player.volume = soundType == .explosion || soundType == .die ? 0.8 : 0.7
            player.play()
            
            // Проверяем, что звук действительно играет
            if !player.isPlaying {
                print("⚠️ SoundManager: Звук \(soundType) не воспроизводится, пробуем еще раз...")
                player.play()
            }
            
            // Сохраняем ссылку, чтобы не удалился до окончания воспроизведения
            let fileName = tempURL.lastPathComponent
            soundPlayers[fileName] = player
            
            // Удаляем после воспроизведения
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                self.soundPlayers.removeValue(forKey: fileName)
                try? FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            print("⚠️ SoundManager: Ошибка воспроизведения звука \(soundType): \(error)")
            // Если не удалось использовать AVAudioPlayer, пробуем SKAction
            fallbackToSKAction(soundType: soundType, node: node)
        }
    }
    
    private func fallbackToSKAction(soundType: SoundType, node: SKNode?) {
        let soundAction = soundType.action
        
        if let node = node {
            // Если передан узел, воспроизводим на нём
            node.run(soundAction)
        } else {
            // Если node == nil, пытаемся найти сцену через другие способы
            // Но в нашем случае всегда передается node (self), так что это редко используется
            // SKAction.playSoundFileNamed может работать и без узла, но это не гарантировано
        }
    }
    
    private func getSoundGenerator(for soundType: SoundType) -> () -> Data? {
        switch soundType {
        case .flap: return RetroSoundGenerator.generateFlapSound
        case .coinCollect: return RetroSoundGenerator.generateCoinSound
        case .explosion: return RetroSoundGenerator.generateExplosionSound
        case .shoot: return RetroSoundGenerator.generateShootSound
        case .hit: return RetroSoundGenerator.generateHitSound
        case .die: return RetroSoundGenerator.generateDieSound
        case .levelComplete: return RetroSoundGenerator.generateLevelCompleteSound
        case .buttonClick: return RetroSoundGenerator.generateButtonClickSound
        case .upgrade: return RetroSoundGenerator.generateUpgradeSound
        case .enemyDie: return RetroSoundGenerator.generateEnemyDieSound
        case .engineStart: return RetroSoundGenerator.generateEngineStartSound
        case .engineLoop: return RetroSoundGenerator.generateEngineLoopSound
        }
    }
    
    // MARK: - Sound Type Enum
    
    enum SoundType {
        case flap          // Прыжок/взмах крыльев
        case coinCollect   // Сбор монеты
        case explosion     // Взрыв
        case shoot         // Выстрел
        case hit           // Попадание
        case die           // Смерть
        case levelComplete // Уровень пройден
        case buttonClick   // Нажатие кнопки
        case upgrade       // Улучшение
        case enemyDie      // Смерть врага
        case engineStart   // Включение двигателя
        case engineLoop    // Работа двигателя (цикл)
        
        var action: SKAction {
            // Пытаемся загрузить звуковой файл, если не найден - используем пустое действие
            // В реальном проекте здесь должны быть добавлены звуковые файлы в Bundle
            let fileName = self.fileName
            let action = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
            
            // Если файл не найден, возвращаем пустое действие (без ошибок)
            // В продакшене здесь должен быть реальный звуковой файл
            return action
        }
        
        var fileName: String {
            switch self {
            case .flap: return "flap"
            case .coinCollect: return "coin"
            case .explosion: return "explosion"
            case .shoot: return "shoot"
            case .hit: return "hit"
            case .die: return "die"
            case .levelComplete: return "level_complete"
            case .buttonClick: return "click"
            case .upgrade: return "upgrade"
            case .enemyDie: return "enemy_die"
            case .engineStart: return "engine_start"
            case .engineLoop: return "engine_loop"
            }
        }
        
    }
}

