//
//  ShareViewController.swift
//  SnapDrillShare
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Share Extension 主入口，接收外部 App 分享的图片并唤起主 App 处理。
//

import UIKit
import UniformTypeIdentifiers
import os

/// Share Extension 视图控制器
///
/// 从微信/QQ/浏览器等 App 接收分享的图片，写入 App Groups 共享容器后
/// 通过 URL Scheme 唤起主 App 进入裁剪→OCR→保存流程。
///
/// 内部纯逻辑（降采样、URL 构造、容器写入）已抽离到 `ShareHelpers.swift`，
/// 由 `SnapDrillShareTests` 覆盖；本类只负责 ExtensionContext 解析与 responder chain 唤起。
final class ShareViewController: UIViewController {

    /// App Groups 共享容器标识符
    private static let appGroupID = "group.com.snapdrill.global"

    /// Extension 专用日志
    private static let logger = Logger(subsystem: "com.snapdrill.share", category: "ShareExtension")

    private var shareTask: Task<Void, Never>?

    private lazy var writer = SharedContainerImageWriter(
        appGroupID: Self.appGroupID,
        logger: Self.logger
    )

    // MARK: - View Body / Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        shareTask = Task {
            await handleSharedContent()
        }
    }

    deinit {
        shareTask?.cancel()
    }

    // MARK: - Private Helpers

    /// 从 NSExtensionItem 中提取图片，保存到共享容器并唤起主 App
    private func handleSharedContent() async {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            Self.logger.error("无法获取 extensionContext inputItems")
            cancelRequest()
            return
        }

        for attachment in attachments
        where attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            do {
                let item = try await attachment.loadItem(
                    forTypeIdentifier: UTType.image.identifier
                )
                if let fileName = writer.save(item: item) {
                    openMainApp(fileName: fileName)
                    return
                }
            } catch {
                Self.logger.error("加载 attachment 失败: \(error.localizedDescription)")
            }
        }

        Self.logger.warning("未找到可处理的图片 attachment")
        cancelRequest()
    }

    /// 通过 URL Scheme 唤起主 App，传递文件名参数
    private func openMainApp(fileName: String) {
        guard let url = ShareDeepLinkBuilder.makeURL(fileName: fileName) else {
            Self.logger.error("无法构造 URL Scheme")
            cancelRequest()
            return
        }
        // Share Extension 无法直接访问 UIApplication.shared，通过 responder chain 打开 URL
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:]) { [weak self] success in
                    DispatchQueue.main.async {
                        guard success else {
                            Self.logger.error("UIApplication.open 返回失败，无法唤起主 App")
                            self?.showOpenMainAppError()
                            return
                        }
                        self?.extensionContext?.completeRequest(returningItems: nil)
                    }
                }
                break
            }
            responder = current.next
        }

        if responder == nil {
            Self.logger.error("Responder chain 中未找到 UIApplication，无法唤起主 App")
            showOpenMainAppError()
        }
    }

    private func showOpenMainAppError() {
        let alert = UIAlertController(
            title: "无法打开 SnapDrill",
            message: "请确认已安装主 App 后重试。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel) { [weak self] _ in
            self?.cancelRequest(message: "无法打开 SnapDrill")
        })
        present(alert, animated: true)
    }

    private func cancelRequest(message: String = "无法处理分享内容") {
        extensionContext?.cancelRequest(withError: NSError(
            domain: "com.snapdrill.share",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: message]
        ))
    }
}
