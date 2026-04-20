//
//  ShareDeepLinkBuilder.swift
//  SnapDrillShare
//
//  Created by NotBad Labs on 2026/04/20.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Share Extension 主 App 唤起 URL 构造（snapdrill://share?file=<name>）。
//

import Foundation

/// 构造主 App 唤起 URL（`snapdrill://share?file=<name>`）。
///
/// 用 URLComponents 而非字符串拼接，自动处理 percent-encoding，
/// 防止文件名含 `&` `?` 等特殊字符时 URL 被截断。
enum ShareDeepLinkBuilder {
    static let defaultScheme = "snapdrill"
    static let defaultHost = "share"
    static let fileQueryKey = "file"

    /// 构造 deep link URL。空文件名返回 nil。
    static func makeURL(
        fileName: String,
        scheme: String = defaultScheme,
        host: String = defaultHost
    ) -> URL? {
        guard !fileName.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.queryItems = [URLQueryItem(name: fileQueryKey, value: fileName)]
        return components.url
    }
}
