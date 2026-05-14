//
//  L10n.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 命名空间根类型。
//  业务分片 enum 由同目录 `L10n+<Module>.swift` 以 `extension L10n { ... }` 形式提供。
//

import Foundation

/// 本地化字符串命名空间。
///
/// 所有 UI 可见字符串的类型安全访问入口。按功能模块分片到 `L10n+<Module>.swift`，
/// 调用路径保持 `L10n.Module.member` 不变。
/// 每条字符串使用 `NSLocalizedString(_:value:comment:)`，中文作为默认值。
nonisolated public enum L10n {}
