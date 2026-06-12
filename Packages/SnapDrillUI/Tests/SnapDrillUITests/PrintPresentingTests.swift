//
//  PrintPresentingTests.swift
//  SnapDrillUITests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PrintPresenting adapter 单元测试（旗舰题库交互 I3）。
//
//  分层说明：
//  - MockPrintPresenter：覆盖 completed / cancelled / throw 三分支 + 调用记录（无需真打印机）。
//  - LivePrintPresenter：覆盖可在 Simulator 无 UI 判定的 noContent 前置守卫。
//  - 局限：completed / cancelled / failed 三态的真实系统呈现须真机 iPhone 17 dogfood
//    （UIPrintInteractionController 在 Simulator 打印支持有限，见 I3 合并 DoD）。
//

import Testing
import UIKit
@testable import SnapDrillUI

struct PrintPresentingTests {

    // MARK: - MockPrintPresenter 三分支

    @Test("Mock 默认返回 completed")
    func mockReturnsCompletedByDefault() async throws {
        let presenter = MockPrintPresenter()
        let outcome = try await presenter.present(
            pdfData: Data([0x25, 0x50, 0x44, 0x46]),
            jobName: "测试任务",
            anchor: .view(UIView())
        )
        #expect(outcome == .completed)
    }

    @Test("Mock 可配置返回 cancelled")
    func mockReturnsCancelled() async throws {
        let presenter = MockPrintPresenter(result: .success(.cancelled))
        let outcome = try await presenter.present(
            pdfData: Data([0x25]),
            jobName: "取消任务",
            anchor: .barButton(UIBarButtonItem())
        )
        #expect(outcome == .cancelled)
    }

    @Test("Mock 可配置抛出错误")
    func mockThrowsConfiguredError() async {
        let presenter = MockPrintPresenter(result: .failure(PrintError.presentationFailed))
        await #expect(throws: PrintError.presentationFailed) {
            _ = try await presenter.present(
                pdfData: Data([0x25]),
                jobName: "失败任务",
                anchor: .rect(CGRect(x: 0, y: 0, width: 10, height: 10), UIView())
            )
        }
    }

    @Test("Mock 记录调用次数与 jobName、数据字节数")
    func mockRecordsInvocations() async throws {
        let presenter = MockPrintPresenter()
        let data = Data([0x25, 0x50, 0x44, 0x46])
        _ = try await presenter.present(pdfData: data, jobName: "第一份", anchor: .view(UIView()))
        _ = try await presenter.present(pdfData: Data([0x25]), jobName: "第二份", anchor: .view(UIView()))

        #expect(presenter.presentCallCount == 2)
        #expect(presenter.presentedJobNames == ["第一份", "第二份"])
        #expect(presenter.presentedDataSizes == [4, 1])
    }

    // MARK: - LivePrintPresenter 前置守卫（Simulator 可判定）

    @Test("LivePrintPresenter 对空数据抛 noContent，不触发系统呈现")
    func livePresenterRejectsEmptyData() async {
        let presenter = LivePrintPresenter()
        await #expect(throws: PrintError.noContent) {
            _ = try await presenter.present(
                pdfData: Data(),
                jobName: "空数据",
                anchor: .view(UIView())
            )
        }
    }

    // MARK: - 呈现 API 路由（iPhone modal vs iPad anchored）

    /// 把携带载荷的 ResolvedPresentation 投影成可断言的标签（避免在生产代码加测试专用 API）。
    private func routeLabel(_ route: LivePrintPresenter.ResolvedPresentation) -> String {
        switch route {
        case .modal: return "modal"
        case .rect: return "rect"
        case .barButton: return "barButton"
        }
    }

    @Test("iPhone idiom 路由到 modal（忽略 view 锚点）")
    func phoneViewRoutesToModal() {
        let route = LivePrintPresenter.resolvePresentation(idiom: .phone, anchor: .view(UIView()))
        #expect(routeLabel(route) == "modal")
    }

    @Test("iPhone idiom 路由到 modal（忽略 barButton 锚点）")
    func phoneBarButtonRoutesToModal() {
        let route = LivePrintPresenter.resolvePresentation(idiom: .phone, anchor: .barButton(UIBarButtonItem()))
        #expect(routeLabel(route) == "modal")
    }

    @Test("iPad idiom + view 锚点路由到 anchored rect")
    func padViewRoutesToRect() {
        let route = LivePrintPresenter.resolvePresentation(idiom: .pad, anchor: .view(UIView()))
        #expect(routeLabel(route) == "rect")
    }

    @Test("iPad idiom + rect 锚点路由到 anchored rect")
    func padRectRoutesToRect() {
        let route = LivePrintPresenter.resolvePresentation(
            idiom: .pad,
            anchor: .rect(CGRect(x: 0, y: 0, width: 10, height: 10), UIView())
        )
        #expect(routeLabel(route) == "rect")
    }

    @Test("iPad idiom + barButton 锚点路由到 anchored barButton")
    func padBarButtonRoutesToBarButton() {
        let route = LivePrintPresenter.resolvePresentation(idiom: .pad, anchor: .barButton(UIBarButtonItem()))
        #expect(routeLabel(route) == "barButton")
    }

    // MARK: - 单次结算门 single-resume（至多一次）

    @Test("SingleResumeGate 仅首次 claim 成功，后续结束信号被忽略（至多结算一次）")
    func gateClaimsAtMostOnce() {
        let gate = SingleResumeGate()
        #expect(gate.claim() == true)
        #expect(gate.claim() == false)
        #expect(gate.claim() == false)
    }

    // MARK: - 类型契约

    @Test("PrintPresentationAnchor 三种 case 可构造")
    func anchorCasesConstruct() {
        let view = UIView()
        let anchors: [PrintPresentationAnchor] = [
            .view(view),
            .rect(CGRect(x: 1, y: 2, width: 3, height: 4), view),
            .barButton(UIBarButtonItem())
        ]
        #expect(anchors.count == 3)
    }

    @Test("PrintPresenting 可作为 any 存在性类型注入与调用")
    func protocolUsableAsExistential() async throws {
        let presenter: any PrintPresenting = MockPrintPresenter(result: .success(.completed))
        let outcome = try await presenter.present(
            pdfData: Data([0x25]),
            jobName: "存在性",
            anchor: .view(UIView())
        )
        #expect(outcome == .completed)
    }
}
