//
//  CaptureRouter.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  拍照模块路由，管理拍照与识别结果页面间的导航。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import UIKit

/// 采集模块导航目标
public enum CaptureDestination: Hashable {
    /// 占位页面
    case placeholder
    /// 扫描结果预览/编辑页面 (含图片)
    case scannerResult(content: String, image: UIImage?)
    /// PDF 页面选择器（传入各页渲染后的图片）
    case pdfPagePicker(pages: [UIImage])
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
    /// 保存成功后置 true，CaptureView 监听此标志自动重新打开摄像头（连续录入）
    public var shouldReopenScanner = false
    /// 目标类型别名
    public typealias Destination = CaptureDestination
    
    /// 初始化路由器
    public init() {}

    /// 导航 push 事件回调（由测试注入，用于验证路由行为）
    public var onPush: ((CaptureDestination) -> Void)?

    // MARK: - Public API

    /// 推入新导航目标（重写默认实现以支持测试钩子）
    public func push(_ destination: CaptureDestination) {
        path.append(destination)
        onPush?(destination)
    }

    /// 恢复草稿（清空已有导航栈，重新推入编辑页）
    public func restoreDraft(_ draft: CaptureDraftService.Draft) {
        path = NavigationPath()
        path.append(CaptureDestination.scannerResult(content: draft.content, image: draft.image))
    }
}
