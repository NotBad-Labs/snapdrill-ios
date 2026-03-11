//
//  SnapDrillUITests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  UI 组件单元测试。

#if canImport(UIKit)
import Testing
import UIKit
import SwiftUI
@testable import SnapDrillUI
@testable import SnapDrillCore

@MainActor
struct SnapDrillUITests {

    // MARK: - Smoke Tests

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

    // MARK: - 视图尺寸断言

    @Test("SnapDrillButton 渲染后视图尺寸大于零")
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

    // MARK: - FlipView 测试

    @Test("FlipView 未翻转时可初始化且不崩溃")
    func flipView_notFlipped_rendersSmokeTest() throws {
        let view = FlipView(isFlipped: false) {
            Text("正面")
        } back: {
            Text("背面")
        }
        let hc = UIHostingController(rootView: view)
        hc.view.layoutIfNeeded()
        #expect(hc.view != nil)
    }

    @Test("FlipView 翻转状态渲染不崩溃")
    func flipView_flipped_rendersSmokeTest() throws {
        let view = FlipView(isFlipped: true) {
            Text("正面")
        } back: {
            Text("背面")
        }
        let hc = UIHostingController(rootView: view)
        hc.view.layoutIfNeeded()
        #expect(hc.view != nil)
    }

    // MARK: - TagInputView 测试

    @Test("TagInputView 空标签列表时可初始化")
    func tagInputView_emptyTags_rendersSmokeTest() throws {
        struct TagTestWrapper: View {
            @State var tags: [String] = []
            @State var text: String = ""
            var body: some View {
                TagInputView(tags: $tags, text: $text)
            }
        }
        let view = TagTestWrapper()
        let hc = UIHostingController(rootView: view)
        hc.view.layoutIfNeeded()
        #expect(hc.view != nil)
    }

    @Test("TagInputView 带初始标签和建议时可渲染")
    func tagInputView_withTagsAndSuggestions_rendersSmokeTest() throws {
        struct TagTestWrapper: View {
            @State var tags: [String] = ["易错", "重点"]
            @State var text: String = ""
            var body: some View {
                TagInputView(tags: $tags, text: $text, suggestions: ["考前必看", "老师强调"])
            }
        }
        let view = TagTestWrapper()
        let hc = UIHostingController(rootView: view)
        hc.view.layoutIfNeeded()
        #expect(hc.view != nil)
    }

    // MARK: - ContextualErrorView 测试

    @Test("ContextualErrorView 各错误类型均返回非空描述")
    func contextualErrorView_allCases_haveNonEmptyDescription() throws {
        let cases: [AppError] = [
            .networkUnavailable,
            .iCloudUnavailable,
            .cameraPermissionDenied,
            .photoLibraryPermissionDenied,
            .ocrFailed(""),
            .exportFailed(""),
            .importFailed(""),
            .dataCorrupted,
            .unknown(NSError(domain: "test", code: -1))
        ]
        for appError in cases {
            #expect(appError.errorDescription?.isEmpty == false, "\(appError) 的 errorDescription 不应为空")
            #expect(appError.recoverySuggestion?.isEmpty == false, "\(appError) 的 recoverySuggestion 不应为空")
            #expect(appError.icon.isEmpty == false, "\(appError) 的 icon 不应为空")
        }
    }

    @Test("ContextualErrorView unknown case 不暴露 localizedDescription")
    func contextualErrorView_unknown_shouldNotExposeSystemError() throws {
        let systemError = NSError(domain: "NSPOSIXErrorDomain", code: 28,
                                  userInfo: [NSLocalizedDescriptionKey: "No space left on device"])
        let appError = AppError.unknown(systemError)

        let suggestion = appError.recoverySuggestion ?? ""
        #expect(!suggestion.contains("No space left"), "unknown 的 recoverySuggestion 不应包含系统错误信息")
        #expect(!suggestion.contains("NSPOSIXErrorDomain"), "unknown 的 recoverySuggestion 不应包含错误域名")
    }

    @Test("ContextualErrorView 渲染不崩溃")
    func contextualErrorView_render_smokeTest() throws {
        let view = ContextualErrorView(error: .networkUnavailable) {}
        let hc = UIHostingController(rootView: view)
        hc.view.layoutIfNeeded()
        #expect(hc.view != nil)
    }

    @Test("ErrorBannerView 渲染不崩溃")
    func errorBannerView_render_smokeTest() throws {
        let view = ErrorBannerView(error: .iCloudUnavailable) {}
        let hc = UIHostingController(rootView: view)
        hc.view.layoutIfNeeded()
        #expect(hc.view != nil)
    }
}
#endif
