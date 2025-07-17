//
//  SwiftDataContainer.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


import Foundation
import SwiftData

actor SwiftDataContainer {
    static let shared = SwiftDataContainer()

    let container: ModelContainer

    private init() {
        do {
            let schema = Schema([
                Question.self
            ])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("❌ SwiftData 容器初始化失败: \(error)")
        }
    }
}
