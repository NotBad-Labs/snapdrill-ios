//
//  DependencyContainer.swift
//  SnapDrill
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  依赖注入容器（Composition Root），管理全局服务与仓库实例。
//

import Foundation
import SnapDrillCore
import SnapDrillData
#if DEBUG
import UIKit
#endif

/// 应用的依赖注入容器 (Composition Root)
///
/// 集中管理所有全局单例和长生命周期对象，确保应用拓扑结构清晰。
final class DependencyContainer {

    // MARK: - Properties

    /// UI 测试模式标志（通过 --uitesting launch argument 激活）
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")

    static let shared = DependencyContainer()

    /// 全局服务容器 (OCR, Analytics 等)
    let services: any ServiceContainer

    /// 顶级导航路由器
    let router: AppRouter

    // MARK: - Initialization

    private init() {
        // UI 测试模式：使用 mock services 与 in-memory 存储。
        if Self.isUITesting {
            let draftService: any CaptureDraftServiceProtocol
            if ProcessInfo.processInfo.arguments.contains("--ui-test-durable-capture-draft") {
                draftService = CaptureDraftService()
            } else {
                draftService = CaptureDraftServiceMock()
            }
            self.services = MockServiceContainer(captureDraft: draftService)
            self.router = AppRouter()
            // 引导页通过 launch argument -hasCompletedOnboarding YES 跳过（进程级，不持久化）
            SnapDrillLogger.generic.info("DependencyContainer: UI 测试模式初始化完成")
            return
        }

        // 1. 分析服务：全球生产基线为零后端行为采集。
        //    Firebase SDK 已删除；生产注入无网络副作用的 NoOpAnalyticsService。
        let analyticsService = NoOpAnalyticsService()

        // 2. 初始化核心服务容器（注入分析实现）
        // Remote Config 已随 Firebase 基础设施删除。
        let liveServices = LiveServiceContainer(
            analytics: analyticsService
        )
        self.services = liveServices

        // 3. 初始化顶级路由器
        self.router = AppRouter()

        SnapDrillLogger.generic.info("DependencyContainer: Composition Root initialized successfully.")
    }

    @MainActor
    func createProfileManager() async -> ProfileManager {
        let manager = await ProfileManager.create(inMemory: Self.isUITesting)
        // L3：种入内置维度（分类/来源/级别/标签），替代旧 3 个分类 seed（S6 删旧）
        manager.activeRepositories.dimension.seedDefaultsIfNeeded()
#if DEBUG
        await seedUITestImageFixtureIfNeeded(into: manager)
#endif
        return manager
    }

#if DEBUG
    private static let imageFixtureLaunchArgument = "--ui-test-seed-image-library"
    private static let imageFixtureContent = "Library Image Fixture"

    @MainActor
    private func seedUITestImageFixtureIfNeeded(into manager: ProfileManager) async {
        guard Self.isUITesting,
              ProcessInfo.processInfo.arguments.contains(Self.imageFixtureLaunchArgument) else {
            return
        }

        let repositories = manager.activeRepositories
        var questionPath: String?
        var answerPath: String?
        do {
            let existing = try repositories.archive.fetchAllModels()
            guard existing.contains(where: { $0.content == Self.imageFixtureContent }) == false else {
                return
            }

            questionPath = try await manager.activeImageStorage.saveImage(
                Self.makeFixtureImage(title: "Question", tint: .systemBlue)
            )
            answerPath = try await manager.activeImageStorage.saveImage(
                Self.makeFixtureImage(title: "Answer", tint: .systemGreen)
            )

            let item = ArchiveItemModel(
                content: Self.imageFixtureContent,
                imagePath: questionPath,
                answerText: "Image fixture answer",
                answerImagePath: answerPath
            )
            item.categoryValues = try Self.fixtureCategoryValues(from: repositories)
            repositories.archive.insert(item)
            try repositories.archive.saveContext()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        } catch {
            repositories.archive.rollbackContext()
            if let questionPath {
                await Self.deleteOrphanedFixtureImage(path: questionPath, storage: manager.activeImageStorage)
            }
            if let answerPath {
                await Self.deleteOrphanedFixtureImage(path: answerPath, storage: manager.activeImageStorage)
            }
            SnapDrillLogger.generic.error("UI test image fixture seed failed: \(error.localizedDescription)")
        }
    }

    private static func deleteOrphanedFixtureImage(path: String, storage: ImageStorage) async {
        do {
            try await storage.deleteImage(path: path)
        } catch {
            SnapDrillLogger.generic.error("UI test fixture image cleanup failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private static func fixtureCategoryValues(from repositories: RepositoryContainer) throws -> [CategoryValueModel] {
        guard let category = try repositories.dimension.fetchDimension(bySystemKey: CategorySystemKey.category) else {
            return []
        }
        let values = repositories.categoryValue.fetchAllModels(in: category)
        return values.filter { $0.name == "题目" || $0.name == "Document" }.prefix(1).map { $0 }
    }

    @MainActor
    private static func makeFixtureImage(title: String, tint: UIColor) -> UIImage {
        let size = CGSize(width: 900, height: 620)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            tint.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let cardRect = CGRect(x: 80, y: 80, width: 740, height: 460)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: cardRect, cornerRadius: 36).fill()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: tint,
                .paragraphStyle: paragraph
            ]
            title.draw(
                in: CGRect(x: 100, y: 235, width: 700, height: 95),
                withAttributes: titleAttributes
            )

            let captionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraph
            ]
            "SnapDrill UI QA".draw(
                in: CGRect(x: 100, y: 340, width: 700, height: 50),
                withAttributes: captionAttributes
            )
        }
    }
#endif
}
