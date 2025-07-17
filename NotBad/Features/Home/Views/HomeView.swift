//
//  HomeView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 问候卡片
                GreetingCard()
                
                // 学习进度概览
                ProgressOverviewCard()
                
                // 快捷操作
                QuickActionsGrid()
                
                // 今日推荐
                TodayRecommendationsCard()
            }
            .padding()
        }
        .navigationTitle("首页")
        .refreshable {
            await viewModel.refresh()
        }
        .environment(viewModel)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}