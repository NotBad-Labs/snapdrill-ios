//
//  DiscoverView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//


//
//  DiscoverView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 推荐题库
                RecommendedLibrarySection()
                
                // 社区精选 (未来功能)
                CommunityHighlightsSection()
                
                // 活动中心 (未来功能)
                ActivityCenterSection()
                
                // 名师推荐 (未来功能)
                TeacherRecommendationsSection()
            }
            .padding()
        }
        .navigationTitle("发现")
        .refreshable {
            await viewModel.refresh()
        }
        .environment(viewModel)
    }
}

// MARK: - Components

struct RecommendedLibrarySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐题库")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    LibraryCard(title: "高中数学", subtitle: "函数与导数", color: .blue)
                    LibraryCard(title: "高中物理", subtitle: "力学基础", color: .green)
                    LibraryCard(title: "高中化学", subtitle: "有机化学", color: .orange)
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LibraryCard: View {
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Text("234 题")
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding()
        .frame(width: 140, height: 100)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CommunityHighlightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("社区精选")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("即将推出")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .frame(height: 120)
                .overlay(
                    VStack {
                        Image(systemName: "person.3.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("社区功能开发中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActivityCenterSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活动中心")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("即将推出")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .frame(height: 100)
                .overlay(
                    VStack {
                        Image(systemName: "party.popper.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                        Text("精彩活动敬请期待")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TeacherRecommendationsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("名师推荐")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("即将推出")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .frame(height: 100)
                .overlay(
                    VStack {
                        Image(systemName: "graduationcap.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("名师课程开发中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
    }
}