//
//  NotBadApp.swift
//  NotBad
//
//  NotBad 错题本 - 应用主入口
//  iOS 26.0+ / Swift 6.0+
//

import SwiftUI
import SwiftData

/// NotBad 错题本应用主入口
///
/// MVP 核心功能：
/// 1. 错题录入 - 拍照 + OCR + 编辑
/// 2. 错题管理 - 查看、搜索、删除
/// 3. 复习系统 - 卡片式复习 + 掌握度标记
@main
struct NotBadApp: App {
    
    // MARK: - Properties
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
        .modelContainer(for: ReviewItem.self)
    }
    
    // MARK: - Lifecycle
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            #if DEBUG
            print("✅ App 进入前台")
            #endif
            // TODO: 刷新数据、恢复状态
            
        case .background:
            #if DEBUG
            print("⏸️ App 进入后台")
            #endif
            // TODO: 自动保存数据、取消 OCR 任务
            
        case .inactive:
            #if DEBUG
            print("⏯️ App 非活动状态")
            #endif
            
        @unknown default:
            break
        }
    }
}
