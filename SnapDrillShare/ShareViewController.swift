//
//  ShareViewController.swift
//  SnapDrillShare
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Share Extension 主入口，接收外部 App 分享的图片并唤起主 App 处理。

import UIKit
import UniformTypeIdentifiers

/// Share Extension 视图控制器
///
/// 从微信/QQ/浏览器等 App 接收分享的图片，写入 App Groups 共享容器后
/// 通过 URL Scheme 唤起主 App 进入裁剪→OCR→保存流程。
final class ShareViewController: UIViewController {

    /// App Groups 共享容器标识符
    private static let appGroupID = "group.com.snapdrill.app"
    /// 待处理图片在共享容器中的文件名
    static let pendingFileName = "pending_share.jpg"

    // MARK: - View Body / Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await handleSharedContent()
        }
    }

    // MARK: - Private Helpers

    /// 从 NSExtensionItem 中提取图片，保存到共享容器并唤起主 App
    private func handleSharedContent() async {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            cancelRequest()
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                do {
                    let item = try await attachment.loadItem(
                        forTypeIdentifier: UTType.image.identifier
                    )
                    if let image = extractImage(from: item) {
                        saveImageToSharedContainer(image)
                        openMainApp()
                        return
                    }
                } catch {
                    // 加载失败，尝试下一个 attachment
                }
            }
        }

        cancelRequest()
    }

    /// 从 NSItemProvider 返回的 item 中提取 UIImage
    private func extractImage(from item: NSSecureCoding?) -> UIImage? {
        if let image = item as? UIImage {
            return image
        }
        if let url = item as? URL,
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if let data = item as? Data {
            return UIImage(data: data)
        }
        return nil
    }

    /// 将图片以 JPEG 格式写入 App Groups 共享容器
    private func saveImageToSharedContainer(_ image: UIImage) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) else { return }

        let pendingURL = containerURL.appendingPathComponent(Self.pendingFileName)
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: pendingURL)
        }
    }

    /// 通过 URL Scheme 唤起主 App
    private func openMainApp() {
        guard let url = URL(string: "snapdrill://share") else {
            cancelRequest()
            return
        }
        // Share Extension 无法直接访问 UIApplication.shared，通过 responder chain 打开 URL
        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url)
                break
            }
            responder = current.next
        }
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancelRequest() {
        extensionContext?.cancelRequest(withError: NSError(
            domain: "com.snapdrill.share",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "无法处理分享内容"]
        ))
    }
}
