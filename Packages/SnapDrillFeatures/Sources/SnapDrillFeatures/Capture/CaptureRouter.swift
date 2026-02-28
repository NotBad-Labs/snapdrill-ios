//
//  CaptureRouter.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集模块导航路由器，管理拍照和录题流程
//

import SwiftUI
import Observation
import SnapDrillUI
import UIKit

/// 采集模块导航目标
public enum CaptureDestination: Hashable {
    /// 占位页面
    case placeholder
    /// 扫描结果预览/编辑页面 (含图片)
    case scannerResult(content: String, image: UIImage?)
}

/// 采集模块路由器
///
/// 负责管理采集流程中的页面导航状态。
/// 遵循 ``FeatureRouter`` 协议，通过 `NavigationPath` 驱动 SwiftUI 导航。
///
/// ## 导航流程
/// 1. **首页**: 显示采集方式选择菜单（相机、相册、手写）。
/// 2. **扫描**: 进入 ``DocumentScannerView`` 进行文档扫描。
/// 3. **结果**: 跳转至 ``CaptureResultView`` 进行预览、编辑元数据和保存。
@MainActor
@Observable
public final class CaptureRouter: FeatureRouter {
    
    // MARK: - Properties
    
    /// 导航路径栈
    ///
    /// 绑定到 Feature 入口的 `NavigationStack(path: $router.path)`。
    public var path = NavigationPath()
    /// 目标类型别名
    public typealias Destination = CaptureDestination
    
    /// 初始化路由器
    public init() {}
    
    // MARK: - Public API
    
    /// 恢复草稿
    public func restoreDraft(_ draft: CaptureDraftService.Draft) {
        // Clear existing stack to be safe? Or just append?
        path = NavigationPath()
        // Push result view akin to finishing a capture
        path.append(CaptureDestination.scannerResult(content: draft.content, image: draft.image))
    }
}
