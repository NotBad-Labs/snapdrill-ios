//
//  DashboardDetailView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//


//
//  DashboardDetailView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 仪表盘的子页面视图
///
/// 职责：
/// - 显示更详细的学习数据或统计
/// - 自身不包含业务逻辑，通过 ViewModel (待创建) 获取数据
struct DashboardDetailView: View {
    var body: some View {
        VStack {
            Text("仪表盘详情")
                .font(.largeTitle)
                .padding()
            Text("这是仪表盘的子页面，展示了独立的导航功能。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("详情")
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardDetailView()
    }
}
#endif
