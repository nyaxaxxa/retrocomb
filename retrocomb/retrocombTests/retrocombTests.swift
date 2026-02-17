//
//  retrocombTests.swift
//  retrocombTests
//
//  Created by Алексей on 07.11.2025.
//

import Foundation
import Testing
@testable import retrocomb

@Suite(.serialized)
struct retrocombTests {

    private func withTemporaryDefaults(_ name: String, perform block: () throws -> Void) rethrows {
        #expect(UserDefaults(suiteName: name) != nil)
        guard let defaults = UserDefaults(suiteName: name) else { return }
        defaults.removePersistentDomain(forName: name)
        defer { defaults.removePersistentDomain(forName: name) }
        try GameData.shared.withTemporaryDefaults(defaults, perform: block)
    }

    @Test func highScoreRecordingStoresOnlyBetterScores() {
        withTemporaryDefaults("retrocomb.tests.highScore") {
            GameData.shared.resetAllData()
            GameData.shared.highScore = 10
            GameData.shared.updateHighScore(25)
            #expect(GameData.shared.highScore == 25)
            GameData.shared.updateHighScore(20)
            #expect(GameData.shared.highScore == 25)
            GameData.shared.updateHighScore(40, isAIMode: true)
            #expect(GameData.shared.highScore == 25)
        }
    }

    @Test func levelRecordsIgnoreLowerScoresAndAI() {
        withTemporaryDefaults("retrocomb.tests.levelRecords") {
            GameData.shared.resetAllData()
            GameData.shared.updateLevelRecord(level: 3, score: 120)
            #expect(GameData.shared.level3Record == 120)
            GameData.shared.updateLevelRecord(level: 3, score: 60)
            #expect(GameData.shared.level3Record == 120)
            GameData.shared.updateLevelRecord(level: 3, score: 340, isAIMode: true)
            #expect(GameData.shared.level3Record == 120)
        }
    }

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
