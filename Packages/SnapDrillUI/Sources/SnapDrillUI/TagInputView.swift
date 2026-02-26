//
//  TagInputView.swift
//  SnapDrillUI
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  标签输入组件，支持添加、删除标签。
//

import SwiftUI

/// 一个支持标签录入和展示的组件
///
/// 用户可以通过输入文本并按下空格或回车来添加标签。
/// 组件会自动处理重复标签，并提供点击删除功能。
public struct TagInputView: View {
    
    // MARK: - Properties
    
    /// 已添加的标签集合
    @Binding var tags: [String]
    /// 当前正在输入的文本字符串
    @Binding var text: String
    
    /// 可选的标签建议列表
    var suggestions: [String] = []
    
    public init(tags: Binding<[String]>, text: Binding<String>, suggestions: [String] = []) {
        self._tags = tags
        self._text = text
        self.suggestions = suggestions
    }
    
    // 过滤后的建议
    private var filteredSuggestions: [String] {
        if text.isEmpty { return [] }
        return suggestions.filter {
            $0.localizedCaseInsensitiveContains(text) && !tags.contains($0)
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chips Container
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.subheadline)
                                Button(action: {
                                    withAnimation {
                                        tags.removeAll { $0 == tag }
                                    }
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                })
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Input Field with Suggestions
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                    
                    TextField("输入标签，空格添加 (e.g. 必修一)", text: $text)
                        .onChange(of: text) { _, newValue in
                            if newValue.hasSuffix(" ") {
                                let newTag = newValue.trimmingCharacters(in: .whitespaces)
                                if !newTag.isEmpty && !tags.contains(newTag) {
                                    withAnimation {
                                        tags.append(newTag)
                                        text = ""
                                    }
                                } else if newTag.isEmpty {
                                    text = "" // Clear just space
                                }
                            }
                        }
                        .submitLabel(.done)
                        .onSubmit {
                            let newTag = text.trimmingCharacters(in: .whitespaces)
                            if !newTag.isEmpty && !tags.contains(newTag) {
                                withAnimation {
                                    tags.append(newTag)
                                    text = ""
                                }
                            }
                        }
                }
                
                // Suggestions List
                if !filteredSuggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                Button {
                                    withAnimation {
                                        tags.append(suggestion)
                                        text = ""
                                    }
                                } label: {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .foregroundStyle(.primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var tags = ["SwiftUI", "Combine", "SwiftData"]
    @Previewable @State var text = ""
    return TagInputView(tags: $tags, text: $text)
        .padding()
}
