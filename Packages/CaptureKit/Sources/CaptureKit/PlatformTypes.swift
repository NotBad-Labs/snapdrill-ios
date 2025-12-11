// CaptureKit - 共享类型定义
//
// 跨平台类型别名，供所有 CaptureKit 模块使用

import Foundation

#if canImport(UIKit)
import UIKit
/// 平台图片类型（iOS: UIImage, macOS: NSImage）
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
/// 平台图片类型（iOS: UIImage, macOS: NSImage）
public typealias PlatformImage = NSImage
#endif
