//
//  LocalizationKeys.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  本地化键值定义，所有 UI 可见字符串的唯一来源。
//

import Foundation

// 本文件是 L10n 命名空间的原始容器，正在按 Issue #666 方案 B 逐步拆分到
// `Support/L10n/L10n+<Module>.swift`。根类型见 `Support/L10n/L10n.swift`。
// `.swiftlint.yml` excluded 条目豁免 file_length，commit 5 收口时一并删除。
// `nonisolated` 需在 extension 级显式标注，defaultIsolation(MainActor) 下
// 不自动从根类型的 `nonisolated public enum L10n` 传递到 extension。
nonisolated extension L10n {

}
