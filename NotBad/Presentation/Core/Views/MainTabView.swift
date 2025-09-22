//
//  MainTabView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 主Tab导航视图
/// 包含5个主要功能模块，通过协调器管理导航
struct MainTabView: View {
    /// 主协调器引用
    @ObservedObject var coordinator: MainCoordinator
    @Environment(\.serviceContainer) private var services

    init(coordinator: MainCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            if let homeCoordinator = coordinator.getTabCoordinator(at: 0) as? HomeCoordinator {
                HomeView(coordinator: homeCoordinator)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("首页")
                    }
                    .tag(0)
            }

            if let libraryCoordinator = coordinator.getTabCoordinator(at: 1) as? LibraryCoordinator {
                let vm = LibraryViewModel(
                    reviewItemService: services.reviewItemServicing,
                    coordinator: libraryCoordinator
                )
                LibraryView(viewModel: vm, coordinator: libraryCoordinator)
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("题库")
                    }
                    .tag(1)
            }

            if let captureCoordinator = coordinator.getTabCoordinator(at: 2) as? CaptureCoordinator {
                let vm = CaptureViewModel(
                    captureUseCase: services.captureReviewItemUseCase,
                    coordinator: captureCoordinator
                )
                CaptureView(viewModel: vm, coordinator: captureCoordinator)
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("拍照")
                    }
                    .tag(2)
            }

            if let discoveryCoordinator = coordinator.getTabCoordinator(at: 3) as? DiscoveryCoordinator {
                DiscoveryView(coordinator: discoveryCoordinator)
                    .tabItem {
                        Image(systemName: "safari.fill")
                        Text("发现")
                    }
                    .tag(3)
            }

            if let profileCoordinator = coordinator.getTabCoordinator(at: 4) as? ProfileCoordinator {
                ProfileView(coordinator: profileCoordinator)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("我的")
                    }
                    .tag(4)
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    let coordinator = MainCoordinator()
    coordinator.start()
    return MainTabView(coordinator: coordinator)
        .withAppEnvironment()
}
