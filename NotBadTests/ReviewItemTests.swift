//
//  ReviewItemTests.swift
//  NotBadTests
//
//  Created by Assistant on 8/20/25.
//

import Testing
import SwiftData
@testable import NotBad

struct ReviewItemTests {
    
    @Test func testDomainTypes() async throws {
        // Test domain types are accessible
        let level = MasteryLevel.notMastered
        let subject = Subject.math
        let result = StudyResult.correct
        
        #expect(level == .notMastered)
        #expect(subject == .math)
        #expect(result == .correct)
    }
    
    @Test func testMasteryLevelProgression() async throws {
        // Test mastery level enum values
        let levels: [MasteryLevel] = [.notMastered, .unclear, .mastered]
        #expect(levels.count == 3)
        #expect(MasteryLevel.allCases.count == 3)
    }
    
    @Test func testSubjectTypes() async throws {
        // Test subject enum values
        let subjects = Subject.allCases
        #expect(subjects.contains(.math))
        #expect(subjects.contains(.chinese))
        #expect(subjects.contains(.english))
        #expect(subjects.contains(.physics))
        #expect(subjects.contains(.chemistry))
        #expect(subjects.contains(.biology))
    }
    
    @Test func testStudyResults() async throws {
        // Test study result enum values
        let results = StudyResult.allCases
        #expect(results.contains(.correct))
        #expect(results.contains(.incorrect))
        #expect(results.contains(.partial))
        #expect(results.contains(.skipped))
    }
}
