//
//  PracticeView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct PracticeView: View {
    @State private var viewModel = PracticeViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // 练习模式选择
            PracticeModeSelector()
            
            // 错题本入口
            MistakeBookSection()
            
            // 标签分类练习
            TagBasedPracticeSection()
            
            // 测验历史
            TestHistorySection()
            
            Spacer()
        }
        .padding()
        .navigationTitle("练习")
        .environment(viewModel)
    }
}

#Preview {
    NavigationStack {
        PracticeView()
    }
}