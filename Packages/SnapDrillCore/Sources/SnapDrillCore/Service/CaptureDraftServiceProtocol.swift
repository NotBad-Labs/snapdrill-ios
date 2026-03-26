//
//  CaptureDraftServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义采集草稿服务协议，支持图片裁剪与临时状态管理。跨域共用（Dashboard 检测、Capture 消费）。
//

#if canImport(UIKit)
import UIKit

/// 采集草稿服务协议
///
/// 定义拍摄草稿的保存、读取与清除契约，便于在生产代码和测试中替换实现。
@MainActor
public protocol CaptureDraftServiceProtocol {
    /// 当前是否存在未保存的草稿
    var hasDraft: Bool { get }
    /// 将图片和已识别文本保存为草稿
    ///
    /// JPEG 压缩和文件写入为异步操作，避免阻塞主线程。
    /// - Parameters:
    ///   - image: 拍摄的原始图片
    ///   - content: OCR 识别文本（可为空字符串）
    ///   - subject: 当前选中的学科（用于恢复提示展示）
    func saveDraft(image: UIImage, content: String, subject: String?) async
    /// 读取已保存的草稿；不存在或数据损坏时返回 `nil`
    func loadDraft() -> CaptureDraftService.Draft?
    /// 清除已保存的草稿（删除磁盘文件和 UserDefaults 记录）
    func clearDraft()
}
#endif
