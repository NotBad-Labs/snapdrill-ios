//
//  FeatureCoordinators.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import Observation

// MARK: - Feature Coordinator Protocol

/// 功能协调器协议
///
/// 定义各个 Tab 功能模块的协调器基础接口
@MainActor
protocol FeatureCoordinatorProtocol: Observable {
    /// 父级 Tab 协调器
    var parent: TabCoordinator { get }
    
    /// 重置导航状态
    func reset()
}

// MARK: - Dashboard Feature Coordinator

/// Dashboard 功能协调器
///
/// 管理首页的导航和状态
@MainActor
@Observable
final class DashboardFeatureCoordinator: FeatureCoordinatorProtocol {
    
    // MARK: - Parent
    
    let parent: TabCoordinator
    
    // MARK: - State
    
    /// 是否显示快速录入
    var showQuickCapture: Bool = false
    
    /// 是否显示复习提示
    var showReviewReminder: Bool = false
    
    // MARK: - Initialization
    
    init(parent: TabCoordinator) {
        self.parent = parent
    }
    
    // MARK: - Actions
    
    /// 开始快速录入
    func startQuickCapture() {
        parent.startCapture()
    }
    
    /// 开始复习
    func startReview() {
        parent.startReviewFromDashboard()
    }
    
    /// 查看题库
    func viewLibrary() {
        parent.selectTab(.library)
    }
    
    /// 查看错题详情
    func viewItemDetail(itemId: UUID) {
        parent.navigateToItemDetail(itemId: itemId)
    }
    
    /// 重置状态
    func reset() {
        showQuickCapture = false
        showReviewReminder = false
        parent.dashboardPath = NavigationPath()
    }
}

// MARK: - Library Feature Coordinator

/// Library 功能协调器
///
/// 管理题库的导航和状态
@MainActor
@Observable
final class LibraryFeatureCoordinator: FeatureCoordinatorProtocol {
    
    // MARK: - Parent
    
    let parent: TabCoordinator
    
    // MARK: - State
    
    /// 当前查看的错题 ID
    var selectedItemId: UUID?
    
    /// 是否显示筛选
    var showFilters: Bool = false
    
    /// 是否显示批量操作
    var showBatchActions: Bool = false
    
    /// 是否处于编辑模式
    var isEditMode: Bool = false
    
    // MARK: - Initialization
    
    init(parent: TabCoordinator) {
        self.parent = parent
    }
    
    // MARK: - Actions
    
    /// 查看错题详情
    func viewItemDetail(itemId: UUID) {
        selectedItemId = itemId
        // 可以在这里 push 到导航堆栈
    }
    
    /// 编辑错题
    func editItem(itemId: UUID) {
        selectedItemId = itemId
        isEditMode = true
    }
    
    /// 开始复习选中的错题
    func reviewSelectedItems(itemIds: [UUID]) {
        // 可以传递数据给 Review 功能
        parent.selectTab(.review)
    }
    
    /// 返回列表
    func backToList() {
        selectedItemId = nil
        isEditMode = false
    }
    
    /// 重置状态
    func reset() {
        selectedItemId = nil
        showFilters = false
        showBatchActions = false
        isEditMode = false
        parent.libraryPath = NavigationPath()
    }
}

// MARK: - Capture Feature Coordinator

/// Capture 功能协调器
///
/// 管理录入流程的导航和状态
@MainActor
@Observable
final class CaptureFeatureCoordinator: FeatureCoordinatorProtocol {
    
    // MARK: - Parent
    
    let parent: TabCoordinator
    
    // MARK: - State
    
    /// 当前录入步骤
    var currentStep: CaptureStep = .selectImage
    
    /// 是否显示相机
    var showCamera: Bool = false
    
    /// 是否显示相册
    var showPhotoLibrary: Bool = false
    
    // MARK: - Initialization
    
    init(parent: TabCoordinator) {
        self.parent = parent
    }
    
    // MARK: - Actions
    
    /// 打开相机
    func openCamera() {
        showCamera = true
    }
    
    /// 打开相册
    func openPhotoLibrary() {
        showPhotoLibrary = true
    }
    
    /// 进入下一步
    func nextStep() {
        switch currentStep {
        case .selectImage:
            currentStep = .recognize
        case .recognize:
            currentStep = .fillForm
        case .fillForm:
            currentStep = .review
        case .review:
            // 保存完成，返回列表
            completeCaptureAndViewLibrary()
        }
    }
    
    /// 返回上一步
    func previousStep() {
        switch currentStep {
        case .selectImage:
            break // 已经是第一步
        case .recognize:
            currentStep = .selectImage
        case .fillForm:
            currentStep = .recognize
        case .review:
            currentStep = .fillForm
        }
    }
    
    /// 完成录入并查看题库
    func completeCaptureAndViewLibrary() {
        reset()
        parent.selectTab(.library)
    }
    
    /// 重置状态
    func reset() {
        currentStep = .selectImage
        showCamera = false
        showPhotoLibrary = false
        parent.capturePath = NavigationPath()
    }
}

// MARK: - Review Feature Coordinator

/// Review 功能协调器
///
/// 管理复习流程的导航和状态
@MainActor
@Observable
final class ReviewFeatureCoordinator: FeatureCoordinatorProtocol {
    
    // MARK: - Parent
    
    let parent: TabCoordinator
    
    // MARK: - State
    
    /// 是否正在复习中
    var isReviewing: Bool = false
    
    /// 当前复习的错题索引
    var currentIndex: Int = 0
    
    /// 复习的错题 ID 列表
    var reviewItemIds: [UUID] = []
    
    /// 是否显示复习完成页
    var showCompletionPage: Bool = false
    
    // MARK: - Initialization
    
    init(parent: TabCoordinator) {
        self.parent = parent
    }
    
    // MARK: - Actions
    
    /// 开始复习
    func startReview(with itemIds: [UUID]) {
        reviewItemIds = itemIds
        currentIndex = 0
        isReviewing = true
        showCompletionPage = false
    }
    
    /// 下一题
    func nextItem() {
        if currentIndex < reviewItemIds.count - 1 {
            currentIndex += 1
        } else {
            completeReview()
        }
    }
    
    /// 上一题
    func previousItem() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    /// 完成复习
    func completeReview() {
        isReviewing = false
        showCompletionPage = true
    }
    
    /// 退出复习
    func exitReview() {
        reset()
    }
    
    /// 查看错题详情
    func viewItemDetail(itemId: UUID) {
        parent.navigateToItemDetail(itemId: itemId)
    }
    
    /// 重置状态
    func reset() {
        isReviewing = false
        currentIndex = 0
        reviewItemIds = []
        showCompletionPage = false
        parent.reviewPath = NavigationPath()
    }
}

// MARK: - Profile Feature Coordinator

/// Profile 功能协调器
///
/// 管理个人中心的导航和状态
@MainActor
@Observable
final class ProfileFeatureCoordinator: FeatureCoordinatorProtocol {
    
    // MARK: - Parent
    
    let parent: TabCoordinator
    
    // MARK: - State
    
    /// 是否显示设置页
    var showSettings: Bool = false
    
    /// 是否显示数据管理
    var showDataManagement: Bool = false
    
    /// 是否显示反馈页
    var showFeedback: Bool = false
    
    /// 是否显示关于页
    var showAbout: Bool = false
    
    // MARK: - Initialization
    
    init(parent: TabCoordinator) {
        self.parent = parent
    }
    
    // MARK: - Actions
    
    /// 打开设置
    func openSettings() {
        showSettings = true
    }
    
    /// 打开数据管理
    func openDataManagement() {
        showDataManagement = true
    }
    
    /// 打开反馈
    func openFeedback() {
        showFeedback = true
    }
    
    /// 打开关于页
    func openAbout() {
        showAbout = true
    }
    
    /// 重置 Onboarding（用于调试）
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
    }
    
    /// 重置状态
    func reset() {
        showSettings = false
        showDataManagement = false
        showFeedback = false
        showAbout = false
        parent.profilePath = NavigationPath()
    }
}
