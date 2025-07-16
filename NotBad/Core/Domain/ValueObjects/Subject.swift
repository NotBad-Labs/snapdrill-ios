//
//  Subject.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation

struct Subject: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let isCustom: Bool
    
    init(name: String, isCustom: Bool = false) {
        self.name = name
        self.isCustom = isCustom
    }
}

// MARK: - 预定义学科
extension Subject {
    static let coreSubjects: [Subject] = [
        Subject(name: "语文"),
        Subject(name: "数学"),
        Subject(name: "外语"),
        Subject(name: "道德与法治"),
        Subject(name: "历史"),
        Subject(name: "地理"),
        Subject(name: "物理"),
        Subject(name: "化学"),
        Subject(name: "生物"),
        Subject(name: "信息技术")
    ]
}