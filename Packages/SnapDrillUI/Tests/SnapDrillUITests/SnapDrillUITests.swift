//
//  SnapDrillUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  UI 组件单元测试：负责保证公共样式核心组件在不同状态下能够被安全实例化而不会引发致命的 SwiftUI 渲染崩溃。
//

import Testing
import SwiftUI
@testable import SnapDrillUI

@MainActor
struct SnapDrillUITests {
    
    // MARK: - Validation of UI Lifecycles
    
    @Test("保证全局基础组件不会因为缺少环境变参而初始化爆错 (Smoke Test)")
    func baseComponentsRenderSmokeTest() throws {
        // 核心组件实例化测试，防止 `Environment` 强解包引发致命崩溃。
        
        // 1. ProgressLoadingView
        let progress = ProgressLoadingView(title: "测试加载")
        let progressHC = UIHostingController(rootView: progress)
        progressHC.view.layoutIfNeeded()
        #expect(progressHC.view != nil)
        
        // 2. ErrorMessageView
        let errorMsg = ErrorMessageView(error: NSError(domain: "test", code: -1), retryAction: {})
        let errorHC = UIHostingController(rootView: errorMsg)
        errorHC.view.layoutIfNeeded()
        #expect(errorHC.view != nil)
        
        // 3. SnapDrillButton
        let button = SnapDrillButton(title: "确认", action: {})
        let btnHC = UIHostingController(rootView: button)
        btnHC.view.layoutIfNeeded()
        #expect(btnHC.view != nil)
    }
}
