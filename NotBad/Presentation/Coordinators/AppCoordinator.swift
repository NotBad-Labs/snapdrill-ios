//
//  AppCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI
// 使用 SwiftUI 的 ObservableObject 支持 environmentObject 注入

/// 应用主协调器
///
/// 职责：
/// - 管理全局导航状态
/// - 协调页面跳转
/// - 处理深度链接
/// - 管理导航栈
@MainActor
final class AppCoordinator: ObservableObject {
     
     // MARK: - Types
    
    /// 导航目的地枚举
    enum Destination: Hashable {
        case welcome
        case home
        case questionList
        case questionDetail(id: String)
        case camera
        case settings
        case profile
    }
    
    // MARK: - Properties
+
+    /// 导航路径
+    @Published var path: [Destination] = []
+
+    /// 当前展示的 Sheet
+    @Published var presentedSheet: Destination?
+
+    /// 当前展示的 FullScreenCover
+    @Published var presentedFullScreenCover: Destination?
     
     // MARK: - Navigation Methods

     /// 导航到指定页面
     func push(_ destination: Destination) {
         path.append(destination)
     }

     /// 返回上一页
     func pop() {
         guard !path.isEmpty else { return }
         path.removeLast()
     }

     /// 返回根页面
     func popToRoot() {
         path.removeAll()
     }

     /// 弹出 Sheet
     func presentSheet(_ destination: Destination) {
         presentedSheet = destination
     }

     /// 弹出全屏页面
     func presentFullScreenCover(_ destination: Destination) {
         presentedFullScreenCover = destination
     }

     /// 关闭当前弹出页面
     func dismiss() {
         presentedSheet = nil
         presentedFullScreenCover = nil
     }

     /// 处理深度链接
     func handleDeepLink(url: URL) {
         // 这里将来实现深度链接逻辑
         // 例如：notbad://question/123
         print("处理深度链接: \(url)")
     }
 }
