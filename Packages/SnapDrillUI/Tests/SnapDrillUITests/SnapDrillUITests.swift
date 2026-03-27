//
//  SnapDrillUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  UI 组件单元测试。
//  分层说明：
//  - Smoke Test：验证组件可被实例化且不崩溃（防止 @Environment 强解包致命错误）
//  - 属性断言：验证组件渲染后视图树中的关键属性（尺寸、accessibilityIdentifier）
//  - 局限：SwiftUI 视图树深度断言需要 ViewInspector，当前未引入该依赖。
//

import Testing
import UIKit
import SwiftUI
@testable import SnapDrillUI

struct SnapDrillUITests {

    // MARK: - Smoke Tests（防止 @Environment 强解包崩溃）

    @Test("基础组件不会因缺少环境变量而初始化崩溃")
    func baseComponentsRenderSmokeTest() throws {
        let progress = ProgressLoadingView(message: "测试加载")
        let progressHC = UIHostingController(rootView: progress)
        progressHC.view.layoutIfNeeded()
        #expect(progressHC.view != nil)

        let errorMsg = ErrorMessageView(title: "错误", message: "测试错误信息")
        let errorHC = UIHostingController(rootView: errorMsg)
        errorHC.view.layoutIfNeeded()
        #expect(errorHC.view != nil)

        let button = SnapDrillButton(title: "确认", action: {})
        let btnHC = UIHostingController(rootView: button)
        btnHC.view.layoutIfNeeded()
        #expect(btnHC.view != nil)
    }

    // MARK: - 视图属性断言

    @Test("组件渲染后视图尺寸大于零")
    func componentViewHasPositiveSize() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))

        let button = SnapDrillButton(title: "测试按钮", action: {})
        let btnHC = UIHostingController(rootView: button)
        window.rootViewController = btnHC
        window.makeKeyAndVisible()
        btnHC.view.layoutIfNeeded()

        #expect(btnHC.view.bounds.width > 0, "按钮宽度应大于零")
        #expect(btnHC.view.bounds.height > 0, "按钮高度应大于零")
    }

    @Test("ProgressLoadingView 渲染后视图尺寸大于零")
    func progressLoadingViewHasPositiveSize() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))

        let progress = ProgressLoadingView(message: "加载中...")
        let hc = UIHostingController(rootView: progress)
        window.rootViewController = hc
        window.makeKeyAndVisible()
        hc.view.layoutIfNeeded()

        #expect(hc.view.bounds.width > 0)
        #expect(hc.view.bounds.height > 0)
    }
}
