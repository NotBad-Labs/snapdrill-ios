//
//  UserProfileView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 用户资料模块的视图
///
/// 职责：
/// - 显示用户的个人信息
/// - 提供设置、帮助和关于等入口
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct UserProfileView: View {
    var body: some View {
        VStack {
            Text("用户资料内容")
                .font(.largeTitle)
                .padding()
            Text("这里将显示你的个人信息、学习成就和应用设置。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("我的")
    }
}

// MARK: - Preview

#if DEBUG
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
#endif
