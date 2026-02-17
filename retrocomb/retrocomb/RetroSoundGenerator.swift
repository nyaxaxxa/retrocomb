//
//  RetroSoundGenerator.swift
//  retrocomb
//
//  Space Flappy Game - Retro Sound Generator (NES/SNES style)
//

import Foundation
import AVFoundation

class RetroSoundGenerator {
    
    // MARK: - Wave Types (как на старых приставках)
    enum WaveType {
        case square      // Прямоугольная волна (NES)
        case triangle    // Треугольная волна (NES)
        case sine        // Синусоида (SNES)
        case noise       // Шум (для взрывов)
    }
    
    // MARK: - Sound Parameters
    
    struct SoundParams {
        let frequency: Double      // Частота в Hz
        let duration: Double       // Длительность в секундах
        let waveType: WaveType    // Тип волны
        let volume: Float          // Громкость 0.0-1.0
        let attack: Double        // Атака (время нарастания)
        let decay: Double         // Затухание
        let sustain: Float        // Поддержка
        let release: Double      // Релиз
        
        init(frequency: Double, duration: Double, waveType: WaveType = .square, 
             volume: Float = 0.5, attack: Double = 0.01, decay: Double = 0.05,
             sustain: Float = 0.7, release: Double = 0.1) {
            self.frequency = frequency
            self.duration = duration
            self.waveType = waveType
            self.volume = volume
            self.attack = attack
            self.decay = decay
            self.sustain = sustain
            self.release = release
        }
    }
    
    // MARK: - Generate Audio Data
    
    static func generateSound(params: SoundParams) -> Data? {
        guard params.duration > 0, params.frequency > 0 else {
            return nil
        }
        
        let sampleRate: Double = 22050  // SNES sample rate
        let totalSamples = Int(params.duration * sampleRate)
        guard totalSamples > 0 else {
            return nil
        }
        
        var audioData = [Int16]()
        audioData.reserveCapacity(totalSamples)
        
        for i in 0..<totalSamples {
            let time = Double(i) / sampleRate
            let sample = generateSample(time: time, params: params, sampleRate: sampleRate)
            audioData.append(sample)
        }
        
        guard !audioData.isEmpty else {
            return nil
        }
        
        return createWAVFile(samples: audioData, sampleRate: Int32(sampleRate))
    }
    
    // MARK: - Generate Single Sample
    
    private static func generateSample(time: Double, params: SoundParams, sampleRate: Double) -> Int16 {
        let phase = time * params.frequency * 2.0 * .pi
        
        // Генерируем базовую волну
        let rawWave: Double
        switch params.waveType {
        case .square:
            rawWave = sin(phase) > 0 ? 1.0 : -1.0
        case .triangle:
            rawWave = (2.0 / .pi) * asin(sin(phase))
        case .sine:
            rawWave = sin(phase)
        case .noise:
            rawWave = Double.random(in: -1.0...1.0)
        }
        
        // Применяем ADSR envelope
        let envelope = calculateEnvelope(time: time, duration: params.duration, 
                                        attack: params.attack, decay: params.decay,
                                        sustain: params.sustain, release: params.release)
        
        let amplitude = rawWave * Double(envelope) * Double(params.volume)
        
        // Конвертируем в 16-bit integer
        let sample = Int16(amplitude * Double(Int16.max))
        return sample
    }
    
    // MARK: - ADSR Envelope
    
    private static func calculateEnvelope(time: Double, duration: Double,
                                         attack: Double, decay: Double,
                                         sustain: Float, release: Double) -> Float {
        if time < attack {
            // Attack phase
            return Float(time / attack)
        } else if time < attack + decay {
            // Decay phase
            let decayTime = time - attack
            return 1.0 - Float(decayTime / decay) * (1.0 - sustain)
        } else if time < duration - release {
            // Sustain phase
            return sustain
        } else {
            // Release phase
            let releaseTime = time - (duration - release)
            return sustain * Float(1.0 - releaseTime / release)
        }
    }
    
    // MARK: - Create WAV File
    
    private static func createWAVFile(samples: [Int16], sampleRate: Int32) -> Data? {
        let numChannels: Int16 = 1  // Mono
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int32(numChannels) * Int32(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * bitsPerSample / 8)
        let dataSize = Int32(samples.count * MemoryLayout<Int16>.size)
        let fileSize = 36 + dataSize
        
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(contentsOf: withUnsafeBytes(of: Int32(fileSize).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(contentsOf: withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) })  // fmt size
        wavData.append(contentsOf: withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })  // PCM
        wavData.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        // Audio samples
        samples.withUnsafeBytes { bytes in
            wavData.append(contentsOf: bytes)
        }
        
        return wavData
    }
    
    // MARK: - Predefined Sounds (NES/SNES style)
    
    static func generateFlapSound() -> Data? {
        // Короткий высокий бип - как прыжок в Super Mario
        let params = SoundParams(
            frequency: 800,
            duration: 0.1,
            waveType: .square,
            volume: 0.4,
            attack: 0.01,
            decay: 0.02,
            sustain: 0.5,
            release: 0.05
        )
        return generateSound(params: params)
    }
    
    static func generateCoinSound() -> Data? {
        // Восходящая мелодия - как сбор монеты
        // Генерируем два тона быстро следующих друг за другом
        guard let samples1 = generateSound(params: SoundParams(
            frequency: 600,
            duration: 0.08,
            waveType: .triangle,
            volume: 0.3
        )) else { return nil }
        
        guard let samples2 = generateSound(params: SoundParams(
            frequency: 900,
            duration: 0.12,
            waveType: .triangle,
            volume: 0.3
        )) else { return samples1 }  // Возвращаем хотя бы первый звук
        
        // Объединяем с небольшим наложением
        return combineSounds([samples1, samples2], overlap: 0.02)
    }
    
    static func generateExplosionSound() -> Data? {
        // Низкий шум с затуханием - как взрыв
        let params = SoundParams(
            frequency: 100,
            duration: 0.3,
            waveType: .noise,
            volume: 0.5,
            attack: 0.01,
            decay: 0.1,
            sustain: 0.3,
            release: 0.15
        )
        return generateSound(params: params)
    }
    
    static func generateShootSound() -> Data? {
        // Короткий писк - как выстрел
        let params = SoundParams(
            frequency: 1200,
            duration: 0.05,
            waveType: .square,
            volume: 0.3,
            attack: 0.005,
            release: 0.03
        )
        return generateSound(params: params)
    }
    
    static func generateHitSound() -> Data? {
        // Средний бип - как попадание
        let params = SoundParams(
            frequency: 400,
            duration: 0.08,
            waveType: .square,
            volume: 0.35,
            attack: 0.01,
            release: 0.05
        )
        return generateSound(params: params)
    }
    
    static func generateDieSound() -> Data? {
        // Нисходящая мелодия - как смерть
        var sounds: [Data] = []
        for freq in stride(from: 600.0, through: 200.0, by: -50.0) {
            if let sound = generateSound(params: SoundParams(
                frequency: freq,
                duration: 0.1,
                waveType: .triangle,
                volume: 0.3
            )) {
                sounds.append(sound)
            }
        }
        guard !sounds.isEmpty else {
            // Если не удалось сгенерировать звуки, создаем простой низкий тон
            return generateSound(params: SoundParams(
                frequency: 200,
                duration: 0.3,
                waveType: .triangle,
                volume: 0.3
            ))
        }
        return combineSounds(sounds, overlap: 0.05)
    }
    
    static func generateLevelCompleteSound() -> Data? {
        // Восходящая мелодия успеха
        var sounds: [Data] = []
        let frequencies: [Double] = [400, 500, 600, 700, 800]
        for freq in frequencies {
            if let sound = generateSound(params: SoundParams(
                frequency: freq,
                duration: 0.15,
                waveType: .sine,
                volume: 0.25
            )) {
                sounds.append(sound)
            }
        }
        guard !sounds.isEmpty else {
            // Если не удалось сгенерировать звуки, создаем простой позитивный тон
            return generateSound(params: SoundParams(
                frequency: 600,
                duration: 0.5,
                waveType: .sine,
                volume: 0.3
            ))
        }
        return combineSounds(sounds, overlap: 0.1)
    }
    
    static func generateButtonClickSound() -> Data? {
        // Очень короткий клик
        let params = SoundParams(
            frequency: 1000,
            duration: 0.03,
            waveType: .square,
            volume: 0.2,
            attack: 0.005,
            release: 0.02
        )
        return generateSound(params: params)
    }
    
    static func generateUpgradeSound() -> Data? {
        // Позитивная восходящая мелодия
        var sounds: [Data] = []
        let frequencies: [Double] = [300, 400, 500]
        for freq in frequencies {
            if let sound = generateSound(params: SoundParams(
                frequency: freq,
                duration: 0.1,
                waveType: .sine,
                volume: 0.25
            )) {
                sounds.append(sound)
            }
        }
        guard !sounds.isEmpty else {
            // Если не удалось сгенерировать звуки, создаем простой позитивный тон
            return generateSound(params: SoundParams(
                frequency: 500,
                duration: 0.2,
                waveType: .sine,
                volume: 0.3
            ))
        }
        return combineSounds(sounds, overlap: 0.05)
    }
    
    static func generateEnemyDieSound() -> Data? {
        // Короткий взрыв
        let params = SoundParams(
            frequency: 200,
            duration: 0.15,
            waveType: .noise,
            volume: 0.4,
            attack: 0.01,
            decay: 0.05,
            sustain: 0.2,
            release: 0.08
        )
        return generateSound(params: params)
    }
    
    static func generateEngineStartSound() -> Data? {
        // Звук включения двигателя - низкий гул с нарастанием
        let params = SoundParams(
            frequency: 150,
            duration: 0.2,
            waveType: .noise,
            volume: 0.3,
            attack: 0.15,
            decay: 0.05,
            sustain: 0.8,
            release: 0.0
        )
        return generateSound(params: params)
    }
    
    static func generateEngineLoopSound() -> Data? {
        // Звук работы двигателя - непрерывный низкий гул
        // Генерируем более длинный звук для циклического воспроизведения
        let params = SoundParams(
            frequency: 120,
            duration: 0.5,  // Короткий цикл для плавного повтора
            waveType: .noise,
            volume: 0.25,
            attack: 0.05,
            decay: 0.0,
            sustain: 1.0,
            release: 0.05
        )
        return generateSound(params: params)
    }
    
    // MARK: - Combine Sounds
    
    private static func combineSounds(_ sounds: [Data], overlap: Double) -> Data? {
        guard !sounds.isEmpty else { return nil }
        guard sounds.count > 1 else { return sounds.first }
        
        // Для простоты просто объединяем звуки последовательно
        // В реальности нужно было бы микшировать с учетом overlap
        var combined = Data()
        for sound in sounds {
            combined.append(sound)
        }
        return combined
    }
    
    // MARK: - Generate Background Music
    
    static func generateBackgroundMusic() -> Data? {
        // Простая ретро-мелодия в стиле NES/SNES
        // Создаем простой паттерн из нескольких нот
        let sampleRate: Double = 22050
        let duration: Double = 2.0  // Короткий паттерн для цикла
        let totalSamples = Int(duration * sampleRate)
        var audioData = [Int16]()
        
        // Простая мелодия: до-ми-соль-до (C-E-G-C)
        let notes: [(freq: Double, start: Double, duration: Double)] = [
            (261.63, 0.0, 0.4),    // C4
            (329.63, 0.4, 0.4),     // E4
            (392.00, 0.8, 0.4),     // G4
            (523.25, 1.2, 0.8)      // C5
        ]
        
        for i in 0..<totalSamples {
            let time = Double(i) / sampleRate
            var sample: Double = 0.0
            
            // Смешиваем все активные ноты
            for note in notes {
                if time >= note.start && time < note.start + note.duration {
                    let noteTime = time - note.start
                    let phase = noteTime * note.freq * 2.0 * .pi
                    let wave = sin(phase) * 0.3  // Тихая фоновая музыка
                    sample += wave
                }
            }
            
            // Добавляем басовую линию
            let bassPhase = time * 130.81 * 2.0 * .pi  // C3
            sample += sin(bassPhase) * 0.15
            
            let amplitude = sample * 0.3  // Общая громкость
            let intSample = Int16(amplitude * Double(Int16.max))
            audioData.append(intSample)
        }
        
        return createWAVFile(samples: audioData, sampleRate: Int32(sampleRate))
    }
    
    // MARK: - Save Sound to File
    
    static func saveSound(_ data: Data, fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("⚠️ RetroSoundGenerator: Ошибка сохранения звука: \(error)")
            return nil
        }
    }
    
    // MARK: - Generate All Sounds
    
    static func generateAllSounds() {
        print("🎵 Генерация ретро-звуков...")
        
        let sounds: [(String, () -> Data?)] = [
            ("flap.wav", generateFlapSound),
            ("coin.wav", generateCoinSound),
            ("explosion.wav", generateExplosionSound),
            ("shoot.wav", generateShootSound),
            ("hit.wav", generateHitSound),
            ("die.wav", generateDieSound),
            ("level_complete.wav", generateLevelCompleteSound),
            ("click.wav", generateButtonClickSound),
            ("upgrade.wav", generateUpgradeSound),
            ("enemy_die.wav", generateEnemyDieSound)
        ]
        
        for (fileName, generator) in sounds {
            if let soundData = generator() {
                if saveSound(soundData, fileName: fileName) != nil {
                    print("✅ Создан: \(fileName) (\(soundData.count) байт)")
                } else {
                    print("❌ Ошибка сохранения: \(fileName)")
                }
            } else {
                print("❌ Ошибка генерации: \(fileName)")
            }
        }
        
        print("🎵 Генерация завершена!")
    }
}

