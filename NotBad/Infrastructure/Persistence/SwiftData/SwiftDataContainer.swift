import Foundation
import SwiftData

@MainActor
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