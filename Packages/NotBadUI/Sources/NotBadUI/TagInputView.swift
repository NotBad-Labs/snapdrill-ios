//
//  TagInputView.swift
//  NotBadUI
//
//  Created by NotBad Architect on 2025/12/31.
//

import SwiftUI

public struct TagInputView: View {
    @Binding var tags: [String]
    @Binding var text: String
    
    public init(tags: Binding<[String]>, text: Binding<String>) {
        self._tags = tags
        self._text = text
    }
    
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
            
            // Input Field
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
        }
    }
}
