//
//  ManualInputViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/18/25.
//

import Foundation
import Observation

@Observable
class ManualInputViewModel {
    // 基础字段
    var content: String = ""
    var answer: String = ""
    var selectedSubjects: [String] = []
    var additionalTags: [String] = []
    var difficulty: Int = 3
    var wrongReason: String = ""
    
    // 计算属性
    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var allTags: [String] {
        selectedSubjects + additionalTags
    }
    
    // 保存方法
    func saveQuestion() {
        // 这里暂时只是打印，后续会实现真正的保存逻辑
        print("保存题目：")
        print("内容：\(content)")
        print("答案：\(answer)")
        print("标签：\(allTags)")
        print("难度：\(difficulty)")
        print("错因：\(wrongReason)")
    }
    
    // 重置方法
    func reset() {
        content = ""
        answer = ""
        selectedSubjects = []
        additionalTags = []
        difficulty = 3
        wrongReason = ""
    }
}