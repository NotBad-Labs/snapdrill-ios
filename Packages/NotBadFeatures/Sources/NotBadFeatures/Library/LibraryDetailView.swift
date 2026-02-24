//
//  LibraryDetailView.swift
//  NotBadFeatureLibrary
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  错题详情页，展示题目的完整信息（原题、答案、解析）。
//

import SwiftUI
import NotBadData
import NotBadUI
import NotBadCore
import SwiftData

/// 题目详情视图
///
/// 展示单一 `ReviewItemModel` 的完整信息，包括图片、长文本和所有元数据。
///
/// ## 功能
/// - **图片预览**: 如果题目包含图片，从 `ImageStorage` 加载并显示。
/// - **元数据展示**: 使用 Badge 样式展示学科、来源和标签。
/// - **复习状态**: 显示题目的创建时间和下一次计划复习时间。
/// - **完整内容**: 可滚动的长文本区域，显示题目的详细描述。
struct LibraryDetailView: View {
    @Bindable var router: LibraryRouter
    
    /// 要展示的题目数据模型
    let item: ReviewItemModel
    
    private let imageStorage = ImageStorage()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Header
                if let imagePath = item.imagePath, 
                   let image = imageStorage.loadImage(path: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .onTapGesture {
                            fullScreenImage = image
                            showingFullScreenImage = true
                        }
                }
                
                // Meta Info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Subject Badge
                        Text(item.subject)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        
                        // Source Badge
                        Text(item.source)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                        
                        Spacer()
                    }
                    
                    if let tags = item.tags, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags) { tag in
                                    Text("#\(tag.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Label(item.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if let nextReview = item.nextReviewAt {
                            Text("下次复习: \(nextReview.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        } else {
                            Text("待安排")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Content
                Text(item.content)
                    .font(.body)
                    .lineSpacing(6)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("题目详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("编辑") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            LibraryEditView(item: item)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let image = fullScreenImage {
                FullScreenImageView(image: image) {
                    showingFullScreenImage = false
                }
            }
        }
    }
    
    @State private var isEditing = false
    @State private var showingFullScreenImage = false
    @State private var fullScreenImage: UIImage?
}

#Preview {
    NavigationStack {
        LibraryDetailView(router: LibraryRouter(), item: ReviewItemModel(content: "Sample Question"))
    }
    .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
