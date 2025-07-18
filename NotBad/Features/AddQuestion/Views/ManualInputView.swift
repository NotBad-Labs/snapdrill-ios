//
//  ManualInputView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/18/25.
//

import SwiftUI

struct ManualInputView: View {
    @State private var viewModel = ManualInputViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 题目内容输入
                    QuestionContentSection()
                    
                    Spacer(minLength: 100) // 为键盘留空间
                }
                .padding()
            }
            .navigationTitle("手动录入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.saveQuestion()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .environment(viewModel)
    }
}

// MARK: - Components

struct QuestionContentSection: View {
    @Environment(ManualInputViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("题目内容")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("请输入题目内容...", text: .constant(viewModel.content), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(5...10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ManualInputView()
}