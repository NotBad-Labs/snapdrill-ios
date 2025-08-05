//
//  UserProfileDetailView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//


//
//  UserProfileDetailView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 用户资料详情视图
///
/// 职责：
/// - 显示用户的详细个人信息或设置选项
/// - 自身不包含业务逻辑，通过 ViewModel (待创建) 获取数据
struct UserProfileDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("用户信息详情")
                .font(.title)
                .fontWeight(.bold)
            
            Text("这里将展示更详细的个人资料和设置。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .navigationTitle("个人资料")
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
struct UserProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileDetailView()
        }
    }
}
#endif
