//
//  LibraryDetailView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  错题详情页，展示题目的完整信息（原题、答案、解析）。
//

import SwiftUI
import SnapDrillDomain
import SnapDrillUI
import SnapDrillCore

/// 题目详情视图
struct LibraryDetailView: View {
    
    // MARK: - Properties
    
    @Bindable var router: LibraryRouter
    
    /// 要展示的题目数据模型 (Domain)
    let item: ReviewItem
    
    @State private var isEditing = false
    @State private var showingFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    
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
                    
                    if !item.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text("#\(tag)")
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
}

#Preview {
    NavigationStack {
        LibraryDetailView(router: LibraryRouter(), item: ReviewItem(id: UUID(), content: "Sample Domain Question", subject: "Math"))
    }
}
