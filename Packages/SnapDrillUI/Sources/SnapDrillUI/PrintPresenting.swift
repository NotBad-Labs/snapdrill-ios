//
//  PrintPresenting.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  一等打印能力的 presentation adapter（旗舰题库交互 I3，改良版 B 契约）。
//
//  分层意图：Core 只负责生成 PDF `Data`（`PDFExportService`），对 UIKit 一无所知；
//  本文件把吃 UIView 的 `UIPrintInteractionController` 呈现逻辑集中在 UI 层，做成
//  可注入的 adapter，既不重复实现也保持可测。Feature View 调用
//  `try await printPresenter.present(pdfData:jobName:anchor:)`，并可按需消费
//  `PrintOutcome`。当前 Feature 在系统打印界面活跃期间用 `AppActivityTracker`
//  记录打印活动；尚未记录“已成功打印”的业务事件。
//
//  契约来源：docs/ui-redesign/flagship-cross-layer-contracts.md · I3。
//  adapter 只消费已有 PDF Data，绝不生成 PDF。
//

import SwiftUI
import UIKit
import os

// MARK: - 结果与错误模型

/// 打印交互的终态。`failed` 不在此枚举，统一走 `throws`（见 `PrintError`）。
///
/// - `completed`：用户确认并提交了打印任务。
/// - `cancelled`：用户取消，或设备无可用打印机而未提交（非错误，不应记录打印）。
public enum PrintOutcome: Sendable, Equatable {
    case completed
    case cancelled
}

/// 打印呈现的定位锚点。`UIPrintInteractionController` 的呈现 API 按设备分流：
/// iPhone 调用模态 `present(animated:)`，不使用锚点；iPad 必须提供锚点，按锚点类型
/// 调用 `present(from:in:animated:)` / `present(from:animated:)` 弹出 popover。
///
/// 该类型持有 `UIView` / `UIBarButtonItem` 等 MainActor 隔离的 UIKit 引用，故不标 `Sendable`；
/// 它只在 `PrintPresenting.present(...)` 的 `@MainActor` 边界内传递，不跨隔离域。
public enum PrintPresentationAnchor {
    /// 以指定视图的 `bounds` 为锚点，在该视图内呈现。
    case view(UIView)
    /// 以指定视图坐标系内的 `rect` 为锚点呈现。
    case rect(CGRect, UIView)
    /// 以工具栏按钮为锚点呈现。
    case barButton(UIBarButtonItem)
}

/// 打印失败错误。仅覆盖 adapter 自身可判定的失败；系统 completionHandler 回传的错误原样透传。
public enum PrintError: Error, Equatable {
    /// 传入的 PDF `Data` 为空或系统判定不可打印。
    case noContent
    /// `UIPrintInteractionController` 未能呈现（present 返回 false）。此时不依赖
    /// completionHandler 是否回调的未文档化行为；`SingleResumeGate` 负责防止潜在的重复结算。
    case presentationFailed
}

// MARK: - 协议

/// 可注入的打印呈现协议。实现把系统打印交互桥接为 async，区分 completed / cancelled / 抛错三态。
///
/// `Sendable` 以便经 `@Environment` 注入并在并发上下文持有；`present` 标 `@MainActor`，
/// 因为底层 `UIPrintInteractionController` 必须在主线程呈现。
public protocol PrintPresenting: Sendable {
    /// 呈现系统打印界面并等待用户决策。
    ///
    /// - Parameters:
    ///   - pdfData: 已生成的 PDF 数据（adapter 不生成、只消费）。
    ///   - jobName: 打印任务名，呈现给系统打印机队列。
    ///   - anchor: iPad popover 定位锚点（iPhone 上被忽略）。
    /// - Returns: `.completed`（已提交）或 `.cancelled`（用户取消 / 无打印机）。
    /// - Throws: `PrintError.noContent` / `PrintError.presentationFailed`，或系统回传的打印错误。
    @MainActor
    func present(pdfData: Data, jobName: String, anchor: PrintPresentationAnchor) async throws -> PrintOutcome
}

// MARK: - 单次结算门

/// 保证打印 continuation **至多** resume 一次的门闩（single-resume）。
///
/// 注意边界：本门闩只防止重复结算，**不**保证系统一定会回调——若 UIKit 既不调用
/// completionHandler、present 又未返回 false，continuation 仍可能不结算（属系统行为，非本类职责）。
///
/// 为何需要：`UIPrintInteractionController` 的公共头文件 / 文档**未**保证
/// 「present 返回 false」与「completionHandler 被调用」二者互斥。若两条路径都触发，
/// 重复 resume 会让 `CheckedContinuation` 运行期 trap。本门闩用最小逻辑保证至多结算一次。
///
/// 实现选型：用 `OSAllocatedUnfairLock` 而非 `@MainActor` 隔离 —— `CompletionHandler`
/// 的隔离语义在 SDK 标注间存在不确定性，无锁原语让 `claim()` 在任意隔离下都可安全调用，
/// 且该类型 `Sendable` 平凡成立，无需 `@unchecked`。
final class SingleResumeGate: Sendable {
    private let resumed = OSAllocatedUnfairLock(initialState: false)

    /// 首次调用返回 `true`（调用方应执行结算），其后恒返回 `false`（应忽略）。
    func claim() -> Bool {
        resumed.withLock { hasResumed in
            guard !hasResumed else { return false }
            hasResumed = true
            return true
        }
    }
}

// MARK: - 生产实现

/// 生产用打印 adapter：包装 `UIPrintInteractionController` + `UIPrintInfo(.general)`，
/// 把 `completionHandler(_, completed, error)` 桥接为 async 结果。
///
/// 无任何可变状态，故 `Sendable` 平凡成立。
public struct LivePrintPresenter: PrintPresenting {

    /// 解析后的呈现方式，由设备 idiom 与锚点共同决定，携带调用所需载荷。
    ///
    /// Apple UIKit SDK 头文件明确分流：`present(animated:)` 用于 iPhone（模态），
    /// `present(from:in:animated:)` / `present(from:animated:)` 用于 iPad（popover，必须锚点）。
    /// 抽成纯函数 `resolvePresentation` 的返回值以便单测路由决策（真实系统呈现须真机 dogfood）。
    enum ResolvedPresentation {
        /// iPhone：模态呈现，忽略锚点。
        case modal
        /// iPad：从视图坐标系内的矩形呈现 popover。
        case rect(CGRect, UIView)
        /// iPad：从工具栏按钮呈现 popover。
        case barButton(UIBarButtonItem)
    }

    /// 路由决策（单一真相源，被 `present` 与单测共同消费）。
    /// - iPhone（及非 iPad idiom）：恒 `.modal`，锚点不参与。
    /// - iPad：按锚点映射到 `.rect` / `.barButton`；`.view` 取其 `bounds` 作矩形。
    static func resolvePresentation(
        idiom: UIUserInterfaceIdiom,
        anchor: PrintPresentationAnchor
    ) -> ResolvedPresentation {
        guard idiom == .pad else { return .modal }
        switch anchor {
        case .view(let view): return .rect(view.bounds, view)
        case .rect(let rect, let view): return .rect(rect, view)
        case .barButton(let item): return .barButton(item)
        }
    }

    public init() {}

    @MainActor
    public func present(
        pdfData: Data,
        jobName: String,
        anchor: PrintPresentationAnchor
    ) async throws -> PrintOutcome {
        // adapter 只消费 PDF Data：空数据或系统判定不可打印 → noContent，绝不呈现空打印界面。
        guard !pdfData.isEmpty, UIPrintInteractionController.canPrint(pdfData) else {
            throw PrintError.noContent
        }

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = jobName

        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = pdfData

        let gate = SingleResumeGate()
        let route = Self.resolvePresentation(idiom: UIDevice.current.userInterfaceIdiom, anchor: anchor)

        return try await withCheckedThrowingContinuation { continuation in
            let completion: UIPrintInteractionController.CompletionHandler = { _, completed, error in
                guard gate.claim() else { return }
                if let error {
                    continuation.resume(throwing: error)
                } else if completed {
                    continuation.resume(returning: .completed)
                } else {
                    // 用户取消或无可用打印机：非错误，交由 Feature 层决定不记录打印（UC5）。
                    continuation.resume(returning: .cancelled)
                }
            }

            let didPresent: Bool
            switch route {
            case .modal:
                didPresent = controller.present(animated: true, completionHandler: completion)
            case .rect(let rect, let view):
                didPresent = controller.present(
                    from: rect, in: view, animated: true, completionHandler: completion
                )
            case .barButton(let item):
                didPresent = controller.present(
                    from: item, animated: true, completionHandler: completion
                )
            }

            // present 返回 false 表示未能呈现；completionHandler 是否仍被调用未文档化，gate 保证至多结算一次。
            if !didPresent, gate.claim() {
                continuation.resume(throwing: PrintError.presentationFailed)
            }
        }
    }
}

// MARK: - 测试替身

/// 测试用打印 adapter：可配置返回 outcome 或抛错，并记录调用，
/// 供 Feature View 的打印决策逻辑（含 UC5「取消 / 无打印机 → 不记打印」）单测，无需真打印机。
///
/// 以 `@MainActor final class` 实现：MainActor 隔离的类隐式满足协议的 `Sendable` 约束，
/// 可变状态由 MainActor 串行化保护，无需 `@unchecked`。
@MainActor
public final class MockPrintPresenter: PrintPresenting {

    /// `present` 的预设结果：`.success(outcome)` 返回该 outcome，`.failure(error)` 抛该错误。
    public var result: Result<PrintOutcome, any Error>

    /// 记录每次 `present` 收到的 jobName，供断言调用次数与参数。
    public private(set) var presentedJobNames: [String] = []

    /// 记录每次 `present` 收到的 PDF 数据字节数（adapter 不应改写数据，便于核对透传）。
    public private(set) var presentedDataSizes: [Int] = []

    /// `present` 被调用的总次数。
    public var presentCallCount: Int { presentedJobNames.count }

    public init(result: Result<PrintOutcome, any Error> = .success(.completed)) {
        self.result = result
    }

    public func present(
        pdfData: Data,
        jobName: String,
        anchor: PrintPresentationAnchor
    ) async throws -> PrintOutcome {
        presentedJobNames.append(jobName)
        presentedDataSizes.append(pdfData.count)
        return try result.get()
    }
}

// MARK: - SwiftUI Environment 注入

private struct PrintPresenterKey: EnvironmentKey {
    // ⚠️ 与 AnalyticsService+Environment 同源约定：EnvironmentKey.defaultValue 用
    // existential `any PrintPresenting`（不可用 `some`，因 getter/setter 类型须完全一致）；
    // 默认值经 `MainActor.assumeIsolated` 构造，匹配包级 `defaultIsolation(MainActor)`。
    static var defaultValue: any PrintPresenting {
        MainActor.assumeIsolated { LivePrintPresenter() }
    }
}

public extension EnvironmentValues {
    /// 打印呈现 adapter。生产默认 `LivePrintPresenter`，测试经
    /// `.environment(\.printPresenter, MockPrintPresenter(...))` 注入替身。
    var printPresenter: any PrintPresenting {
        get { self[PrintPresenterKey.self] }
        set { self[PrintPresenterKey.self] = newValue }
    }
}
