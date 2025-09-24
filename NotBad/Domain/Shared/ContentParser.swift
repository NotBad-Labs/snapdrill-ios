//
//  ContentParser.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// 复习项内容数据结构
/// 用于表示题目和答案的基本数据
struct ParsedContent {
    let question: String
    let answer: String
    
    var isValid: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}