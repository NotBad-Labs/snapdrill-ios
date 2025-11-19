//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 9/20/25.
//
//  Updated: 2025-11-19 (Phase 1: 工程升级到 Swift 6.3 + iOS 26.1)
//  PRD 章节：§3.1 技术栈
//  单一事实来源（SSoT）：docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.2.md
//  本文件是应用唯一入口，所有实现严格基于 PRD v6.2 派生

import SwiftUI

/// NotBad 错题本应用主入口
///
/// 职责：
/// - 应用启动与配置
/// - 场景生命周期管理
/// - 根视图展示
///
/// 设计原则（来自 PRD v6.2）：
/// - 本地优先（Local-First）
/// - 端侧优先（On-Device First）
/// - 隐私优先（Privacy by Design）
/// - 免费无广告
@main
struct NotBadApp: App {
    
    // MARK: - Properties
    
    /// 监听应用前后台状态
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
    }
    
    // MARK: - Lifecycle Handlers
    
    /// 处理应用场景状态变化
    /// - Parameters:
    ///   - oldPhase: 旧状态
    ///   - newPhase: 新状态
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // 前台激活：刷新数据、恢复状态
            print("✅ NotBad 进入前台")
            
        case .background:
            // 后台：持久化数据、清理资源
            print("⏸️ NotBad 进入后台")
            
        case .inactive:
            // 非活动状态：暂停操作
            print("⏯️ NotBad 处于非活动状态")
            
        @unknown default:
            break
        }
    }
}

// MARK: - Root View (Placeholder)

/// 根视图占位
/// TODO: 根据 PRD v6.2 §4.2 实现完整导航流程（欢迎屏 → 主界面）
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("NotBad 错题本")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("基于 PRD v6.2 重新开发中")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("本地优先 · 隐私优先 · 免费无广告")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }
}
