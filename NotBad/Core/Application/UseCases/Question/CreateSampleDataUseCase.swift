//
//  CreateSampleDataUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  CreateSampleDataUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

actor CreateSampleDataUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute() async throws {
        // 检查是否已有数据
        let descriptor = FetchDescriptor<Question>()
        let existingQuestions = try modelContext.fetch(descriptor)
        
        guard existingQuestions.isEmpty else { return }
        
        let sampleQuestions = createSampleQuestions()
        
        for question in sampleQuestions {
            modelContext.insert(question)
        }
        
        try modelContext.save()
    }
    
    private func createSampleQuestions() -> [Question] {
        return [
            Question(
                content: "计算：3 + 5 × 2 = ?",
                answer: "13",
                tags: ["数学", "运算", "易错"],
                wrongReason: "忘记先算乘法再算加法",
                difficulty: 2
            ),
            Question(
                content: "英语语法：He _____ to school every day. (go/goes)",
                answer: "goes",
                tags: ["英语", "语法", "第三人称单数"],
                wrongReason: "忘记第三人称单数要加s",
                difficulty: 2
            ),
            Question(
                content: "物理：光在真空中的传播速度是多少？",
                answer: "3×10^8 m/s",
                tags: ["物理", "光学", "常数"],
                difficulty: 3
            ),
            Question(
                content: "化学：水的化学分子式是什么？",
                answer: "H₂O",
                tags: ["化学", "分子式", "基础"],
                difficulty: 1
            ),
            Question(
                content: "数学：求解方程 2x + 3 = 11",
                answer: "x = 4",
                tags: ["数学", "方程", "代数"],
                wrongReason: "计算过程中符号搞错了",
                difficulty: 3
            ),
            Question(
                content: "历史：中华人民共和国成立于哪一年？",
                answer: "1949年",
                tags: ["历史", "建国", "重要事件"],
                difficulty: 1
            ),
            Question(
                content: "地理：中国最长的河流是什么？",
                answer: "长江",
                tags: ["地理", "河流", "中国"],
                difficulty: 1
            ),
            Question(
                content: "生物：植物进行光合作用的主要器官是什么？",
                answer: "叶子",
                tags: ["生物", "植物", "光合作用"],
                difficulty: 2
            ),
            Question(
                content: "数学：圆的面积公式是什么？",
                answer: "πr²",
                tags: ["数学", "几何", "公式"],
                wrongReason: "记成了周长公式2πr",
                difficulty: 2
            ),
            Question(
                content: "英语：'苹果'的英文单词怎么拼写？",
                answer: "apple",
                tags: ["英语", "单词", "水果"],
                difficulty: 1
            ),
            Question(
                content: "物理：牛顿第一定律的内容是什么？",
                answer: "物体在不受外力作用时保持静止或匀速直线运动状态",
                tags: ["物理", "牛顿定律", "力学"],
                difficulty: 4
            ),
            Question(
                content: "化学：氧气的化学符号是什么？",
                answer: "O₂",
                tags: ["化学", "化学符号", "气体"],
                difficulty: 1
            ),
            Question(
                content: "数学：sin(30°) = ?",
                answer: "1/2",
                tags: ["数学", "三角函数", "特殊角"],
                wrongReason: "记成了cos(30°)的值",
                difficulty: 4
            ),
            Question(
                content: "语文：《静夜思》的作者是谁？",
                answer: "李白",
                tags: ["语文", "古诗", "李白"],
                difficulty: 1
            ),
            Question(
                content: "信息技术：HTTP的全称是什么？",
                answer: "HyperText Transfer Protocol",
                tags: ["信息技术", "网络", "协议"],
                difficulty: 3
            )
        ]
    }
}
