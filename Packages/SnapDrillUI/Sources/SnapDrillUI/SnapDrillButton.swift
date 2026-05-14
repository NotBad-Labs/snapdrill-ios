//
//  SnapDrillButton.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  全局统一的按钮组件
//

import SwiftUI

/// 统一风格的应用程序主按钮
///
/// 一个遵循 SnapDrill 设计系统的标准化操作按钮。
/// 它默认使用 `.borderedProminent` 样式，强调主要操作。
///
/// ## 示例代码
/// ```swift
/// SnapDrillButton(title: "提交") {
///     submitData()
/// }
/// ```
public struct SnapDrillButton: View {
    
    // MARK: - Properties
    
    /// 按钮标题
    ///
    /// 显示在按钮中间的描述性文字。
    let title: String
    
    /// 按钮点击事件回调
    ///
    /// 用户点击按钮时触发的闭包。
    let action: () -> Void
    
    /// 初始化按钮
    /// - Parameters:
    ///   - title: 按钮显示的文字
    ///   - action: 点击后的操作
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
    }
}

#Preview {
    VStack(spacing: 20) {
        SnapDrillButton(title: "主要操作") { }
        SnapDrillButton(title: "次要操作") { }
    }
    .padding()
}
