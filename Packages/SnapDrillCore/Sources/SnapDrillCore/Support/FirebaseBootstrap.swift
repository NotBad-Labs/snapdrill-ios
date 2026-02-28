//
//  FirebaseBootstrap.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/26.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import FirebaseCore

/// Firebase 引导程序
///
/// 用于封装 Firebase 的初始化逻辑，避免主 App Target 直接依赖 FirebaseCore。
public enum FirebaseBootstrap {
    /// 配置 Firebase 环境
    public static func configure() {
        FirebaseApp.configure()
    }
}
