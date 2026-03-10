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
import os

/// Share Extension 视图控制器
///
/// 从微信/QQ/浏览器等 App 接收分享的图片，写入 App Groups 共享容器后
/// 通过 URL Scheme 唤起主 App 进入裁剪→OCR→保存流程。
///
/// **内存策略**：Share Extension 有 120MB 硬限制。优先直接拷贝/写入原始数据，
/// 避免将大图解码为 UIImage（5000x8000 图片解码后 ~160MB，必然 OOM）。
/// 仅在 NSItemProvider 返回 UIImage 对象时才 fallback 做 JPEG 编码（含降采样）。
final class ShareViewController: UIViewController {

    /// App Groups 共享容器标识符
    private static let appGroupID = "group.com.snapdrill.app"

    /// Extension 专用日志
    private static let logger = Logger(subsystem: "com.snapdrill.share", category: "ShareExtension")

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
            Self.logger.error("无法获取 extensionContext inputItems")
            cancelRequest()
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                do {
                    let item = try await attachment.loadItem(
                        forTypeIdentifier: UTType.image.identifier
                    )
                    if let fileName = saveToSharedContainer(item: item) {
                        openMainApp(fileName: fileName)
                        return
                    }
                } catch {
                    Self.logger.error("加载 attachment 失败: \(error.localizedDescription)")
                }
            }
        }

        Self.logger.warning("未找到可处理的图片 attachment")
        cancelRequest()
    }

    /// 将 NSItemProvider 返回的 item 保存到 App Groups 共享容器
    ///
    /// 优先直接拷贝/写入原始字节，避免解码为 UIImage 导致 Extension OOM。
    /// 仅在 item 为 UIImage 对象时才 fallback 做 JPEG 编码（含降采样至 2048px）。
    ///
    /// - Returns: 保存成功的文件名（UUID.jpg），失败返回 nil
    private func saveToSharedContainer(item: NSSecureCoding?) -> String? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) else {
            Self.logger.error("无法获取 App Groups 共享容器路径")
            return nil
        }

        let fileName = UUID().uuidString + ".jpg"
        let destURL = containerURL.appendingPathComponent(fileName)

        // 优先路径 1：URL 类型 — 直接拷贝文件，零内存开销
        if let url = item as? URL {
            do {
                try FileManager.default.copyItem(at: url, to: destURL)
                Self.logger.info("通过文件拷贝保存图片: \(fileName)")
                return fileName
            } catch {
                Self.logger.error("文件拷贝失败: \(error.localizedDescription)")
                return nil
            }
        }

        // 优先路径 2：Data 类型 — 直接写入原始字节，不解码
        if let data = item as? Data {
            do {
                try data.write(to: destURL, options: .atomic)
                Self.logger.info("通过 Data 直接写入保存图片: \(fileName)")
                return fileName
            } catch {
                Self.logger.error("Data 写入失败: \(error.localizedDescription)")
                return nil
            }
        }

        // Fallback 路径：UIImage 类型 — 降采样后编码为 JPEG
        if let image = item as? UIImage {
            let safeImage = downsampleIfNeeded(image, maxDimension: 2048)
            if let data = safeImage.jpegData(compressionQuality: 0.85) {
                do {
                    try data.write(to: destURL, options: .atomic)
                    Self.logger.info("通过 UIImage fallback 保存图片: \(fileName)")
                    return fileName
                } catch {
                    Self.logger.error("UIImage JPEG 写入失败: \(error.localizedDescription)")
                    return nil
                }
            }
        }

        Self.logger.warning("无法从 item 中提取图片数据")
        return nil
    }

    /// 对超大图片降采样，防止 JPEG 编码时内存溢出
    private func downsampleIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// 通过 URL Scheme 唤起主 App，传递文件名参数
    private func openMainApp(fileName: String) {
        guard let url = URL(string: "snapdrill://share?file=\(fileName)") else {
            Self.logger.error("无法构造 URL Scheme")
            cancelRequest()
            return
        }
        // Share Extension 无法直接访问 UIApplication.shared，通过 responder chain 打开 URL
        var responder: UIResponder? = self
        var opened = false
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url)
                opened = true
                break
            }
            responder = current.next
        }

        if !opened {
            Self.logger.error("Responder chain 中未找到 UIApplication，无法唤起主 App")
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
