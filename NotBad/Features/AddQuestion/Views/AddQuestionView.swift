//
//  AddQuestionView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct AddQuestionView: View {
    @State private var viewModel = AddQuestionViewModel()
    @Environment(TabCoordinator.self) private var tabCoordinator
    
    var body: some View {
        VStack(spacing: 24) {
            // 添加方式选择
            AddMethodSelector()
            
            // 拍照按钮
            CameraButton {
                tabCoordinator.presentCamera()
            }
            
            // 手动录入按钮
            ManualInputButton {
                // 跳转到手动录入界面
            }
            
            // 最近添加的题目
            RecentQuestionsSection()
            
            Spacer()
        }
        .padding()
        .navigationTitle("添加题目")
        .environment(viewModel)
    }
}

// MARK: - Components

struct AddMethodSelector: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择添加方式")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("通过拍照识别或手动输入来添加题目")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CameraButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("拍照识别")
                        .font(.headline)
                    Text("智能识别题目内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

struct ManualInputButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("手动录入")
                        .font(.headline)
                    Text("直接输入题目内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct RecentQuestionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近添加")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                RecentQuestionRow(title: "解方程：x² + 2x - 3 = 0", time: "2小时前")
                RecentQuestionRow(title: "求导数：f(x) = x³ + 2x", time: "昨天")
                RecentQuestionRow(title: "化简：√(x² + 4x + 4)", time: "3天前")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecentQuestionRow: View {
    let title: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AddQuestionView()
    }
}