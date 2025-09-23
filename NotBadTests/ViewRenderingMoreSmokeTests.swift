//
//  ViewRenderingMoreSmokeTests.swift
//  NotBadTests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class ViewRenderingMoreSmokeTests: XCTestCase {

    // 基础与壳层
    func testLaunchScreenView_Renders() {
        let view = LaunchScreenView()
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testMainTabView_RendersWithCoordinator() {
        let appEnv = AppEnvironment.createTestEnvironment()
        let main = MainCoordinator()
        main.start()
        let view = MainTabView(coordinator: main).withAppEnvironment(appEnv)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 发现与详情
    func testDiscoveryDetailView_Renders() {
        let coordinator = DiscoveryCoordinator()
        let view = DiscoveryDetailView(itemId: "id-1", coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 主页详情
    func testHomeDetailView_Renders_InvalidIdProgress() {
        let coordinator = HomeCoordinator()
        let view = HomeDetailView(itemId: UUID().uuidString, coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 题库详情与练习模式占位
    func testLibraryDetailView_Renders_InvalidIdProgress() {
        let coordinator = LibraryCoordinator()
        let view = LibraryDetailView(itemId: UUID().uuidString, coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testPracticeModeView_Renders() {
        let coordinator = LibraryCoordinator()
        let view = PracticeModeView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // Profile 子页面
    func testProfileSettingsView_Renders() {
        let coordinator = ProfileCoordinator()
        let view = ProfileSettingsView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testAboutView_Renders() {
        let coordinator = ProfileCoordinator()
        let view = AboutView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testProfileDetailView_Renders() {
        let coordinator = ProfileCoordinator()
        let view = ProfileDetailView(itemId: "detail-1", coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // Library/Home 详情（有效ID以覆盖更多分支，包括标签与备注）
    func testLibraryDetailView_Renders_WithValidItem() async throws {
        // Seed one item into shared ServiceContainer
        let createdId = try await ServiceContainer.shared.reviewItemService.createReviewItem(
            question: "预览：三角函数的基本关系？",
            answer: "sin^2 x + cos^2 x = 1",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.medium.rawValue,
            tags: ["三角", "恒等式"],
            notes: "用于 UI 渲染覆盖"
        )

        let coordinator = LibraryCoordinator()
        let view = LibraryDetailView(itemId: createdId.value.uuidString, coordinator: coordinator)
            .withAppEnvironment(AppEnvironment.createTestEnvironment())
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        // allow `.task { await viewModel.load() }` to complete
        try await Task.sleep(nanoseconds: 150_000_000)
    }

    func testHomeDetailView_Renders_WithValidItem() async throws {
        let createdId = try await ServiceContainer.shared.reviewItemService.createReviewItem(
            question: "预览：圆的面积公式？",
            answer: "S = πr^2",
            subject: ReviewItem.Subject.math.rawValue,
            difficulty: ReviewItem.Difficulty.easy.rawValue,
            tags: ["几何", "基础"],
            notes: "用于 UI 渲染覆盖"
        )

        let coordinator = HomeCoordinator()
        let view = HomeDetailView(itemId: createdId.value.uuidString, coordinator: coordinator)
            .withAppEnvironment(AppEnvironment.createTestEnvironment())
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        try await Task.sleep(nanoseconds: 150_000_000)
    }

    // Library 内容视图的多分支覆盖
    func testLibraryContentView_Renders_LoadingState() {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let coordinator = LibraryCoordinator()
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        vm.isLoading = true
        let view = LibraryContentView(viewModel: vm)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testLibraryContentView_Renders_WithItems() throws {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let coordinator = LibraryCoordinator()
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        // Seed one in-memory item for immediate rendering
        let item = try ReviewItem(
            question: "示例：勾股定理",
            answer: "a^2 + b^2 = c^2",
            subject: .math,
            difficulty: .easy,
            tags: ["几何", "基础"],
            notes: "演示"
        )
        vm.reviewItems = [item]
        vm.isLoading = false
        let view = LibraryContentView(viewModel: vm)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // Capture 子页面
    func testOCRResultView_Renders_WithImage() {
        // 生成 1x1 像素透明 PNG 的 Base64
        let base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/aqk0HcAAAAASUVORK5CYII="
        let coordinator = CaptureCoordinator()
        let view = OCRResultView(imageBase64: base64, coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testOCREditView_Renders() {
        let coordinator = CaptureCoordinator()
        let view = OCREditView(initialText: "text", coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testSaveReviewItemView_Renders() {
        let appEnv = AppEnvironment.createTestEnvironment()
        let coordinator = CaptureCoordinator()
        let view = SaveReviewItemView(content: "题干示例", coordinator: coordinator).withAppEnvironment(appEnv)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }
}
