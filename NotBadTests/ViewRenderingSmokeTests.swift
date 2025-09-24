//
//  ViewRenderingSmokeTests.swift
//  NotBadTests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class ViewRenderingSmokeTests: XCTestCase {

    // 渲染 ContentView 以覆盖其 body 代码
    func testContentView_RendersInHostingController() {
        let view = ContentView()
        let hosting = UIHostingController(rootView: view)

        // 触发展示与布局，这会执行 body 构建路径
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 渲染 PhotoLibraryView 的初始状态（未选择照片）
    func testPhotoLibraryView_InitialState_Renders() {
        // 直接构建最小依赖的 ViewModel 与 Coordinator
        let repository = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repository)
        let useCase = CaptureReviewItemUseCase(reviewItemService: service)
        let coordinator = CaptureCoordinator()
        let vm = CaptureViewModel(captureUseCase: useCase, coordinator: coordinator)

        let view = PhotoLibraryView(viewModel: vm)
        let hosting = UIHostingController(rootView: view)

        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 渲染 CaptureView 主界面（不触发系统相机权限，仅构建 UI）
    func testCaptureView_MainContent_Renders() {
        let repository = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repository)
        let useCase = CaptureReviewItemUseCase(reviewItemService: service)
        let coordinator = CaptureCoordinator()
        let vm = CaptureViewModel(captureUseCase: useCase, coordinator: coordinator)

        let view = CaptureView(viewModel: vm, coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)

        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 渲染 Home/Library/Discovery/Profile 主视图
    func testHomeView_Renders() {
        let coordinator = HomeCoordinator()
        let view = HomeView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testLibraryView_Renders() {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let coordinator = LibraryCoordinator()
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        let view = LibraryView(viewModel: vm, coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testDiscoveryView_Renders() {
        let coordinator = DiscoveryCoordinator()
        let view = DiscoveryView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testProfileView_Renders() {
        let coordinator = ProfileCoordinator()
        let view = ProfileView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    // 渲染 RootView 与 AppShellView（带环境注入）
    func testRootView_RendersWithEnvironment() {
        let appEnv = AppEnvironment.createTestEnvironment()
        let view = RootView().withAppEnvironment(appEnv)
        let hosting = UIHostingController(rootView: view)
        // RootView 在 .task 中会触发启动流程，但这里仅验证渲染路径
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testAppShellView_RendersWithEnvironment() {
        let appEnv = AppEnvironment.createTestEnvironment()
        let view = AppShellView().environmentObject(appEnv)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }
}
