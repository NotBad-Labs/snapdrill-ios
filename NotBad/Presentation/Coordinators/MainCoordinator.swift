//
//  MainCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 主协调器
/// 管理应用的顶层 TabView 导航和全局导航状态
@MainActor
class MainCoordinator: BaseCoordinator {
    /// 当前选中的Tab索引
    @Published var selectedTab: Int = 0

    /// 各个Tab的协调器（延迟初始化）
    lazy var homeCoordinator: HomeCoordinator = {
        let coordinator = HomeCoordinator()
        coordinator.parent = self
        return coordinator
    }()
    
    lazy var captureCoordinator: CaptureCoordinator = {
        let coordinator = CaptureCoordinator()
        coordinator.parent = self
        return coordinator
    }()
    
    lazy var libraryCoordinator: LibraryCoordinator = {
        let coordinator = LibraryCoordinator()
        coordinator.parent = self
        return coordinator
    }()
    
    lazy var discoveryCoordinator: DiscoveryCoordinator = {
        let coordinator = DiscoveryCoordinator()
        coordinator.parent = self
        return coordinator
    }()
    
    lazy var profileCoordinator: ProfileCoordinator = {
        let coordinator = ProfileCoordinator()
        coordinator.parent = self
        return coordinator
    }()

    override func start() {
        selectedTab = 0  // 默认显示首页
        AppLogger.info(.coordinator, "MainCoordinator.start -> selectedTab=0")
    }

    override func coordinate(to route: Route) {
        AppLogger.debug(.coordinator, "MainCoordinator.coordinate -> \(route)")
        switch route {
        case .home:
            selectedTab = 0
            AppLogger.info(.coordinator, "Switch tab -> home(0)")
        case .library:
            selectedTab = 1
            AppLogger.info(.coordinator, "Switch tab -> library(1)")
        case .capture:
            selectedTab = 2
            AppLogger.info(.coordinator, "Switch tab -> capture(2)")
        case .discovery:
            selectedTab = 3
            AppLogger.info(.coordinator, "Switch tab -> discovery(3)")
        case .profile:
            selectedTab = 4
            AppLogger.info(.coordinator, "Switch tab -> profile(4)")
            
        // MARK: - 跨模块导航处理
        case .navigateToLibraryAfterCapture:
            selectedTab = 1  // 切换到Library Tab
            libraryCoordinator.coordinate(to: .library)  // 重置到根视图
            AppLogger.info(.coordinator, "Cross-tab: navigateToLibraryAfterCapture -> library root")
            
        case .navigateToLibraryFromHome:
            selectedTab = 1
            libraryCoordinator.coordinate(to: .library)
            AppLogger.info(.coordinator, "Cross-tab: navigateToLibraryFromHome -> library root")
            
        case .navigateToPracticeFromLibrary:
            selectedTab = 1
            libraryCoordinator.coordinate(to: .practiceMode)
            AppLogger.info(.coordinator, "Cross-tab: navigateToPracticeFromLibrary -> practiceMode")
            
        default:
            getCurrentTabCoordinator()?.coordinate(to: route)
        }
    }

    /// 获取当前Tab的协调器
    func getCurrentTabCoordinator() -> (any Coordinator)? {
        switch selectedTab {
        case 0: return homeCoordinator
        case 1: return libraryCoordinator
        case 2: return captureCoordinator
        case 3: return discoveryCoordinator
        case 4: return profileCoordinator
        default: return nil
        }
    }

    /// 获取指定Tab的协调器
    func getTabCoordinator(at index: Int) -> (any Coordinator)? {
        switch index {
        case 0: return homeCoordinator
        case 1: return libraryCoordinator
        case 2: return captureCoordinator
        case 3: return discoveryCoordinator
        case 4: return profileCoordinator
        default: return nil
        }
    }
}
