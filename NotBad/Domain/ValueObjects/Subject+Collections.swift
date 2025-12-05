//
//  Subject+Collections.swift
//  NotBad
//
//  学科静态集合扩展
//

import Foundation

// MARK: - Static Collections

extension Subject {
    /// 主要学科（语数英）
    static let coreSubjects: [Subject] = [.chinese, .math, .english]

    /// 中考学科
    static let juniorExamSubjects: [Subject] = [
        .chinese, .math, .english,
        .physics, .chemistry,
        .history, .geography, .politics, .biology
    ]

    /// 高考学科
    static let seniorExamSubjects: [Subject] = [
        .chinese, .math, .english,
        .physics, .chemistry, .biology,
        .history, .geography, .politics
    ]

    /// 理科组合（物化生）
    static let scienceCombo: [Subject] = [.physics, .chemistry, .biology]

    /// 文科组合（史地政）
    static let artsCombo: [Subject] = [.history, .geography, .politics]
}
