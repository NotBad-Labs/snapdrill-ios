//
//  ItemRow.swift
//  NotBad
//
//  错题列表行组件
//
//  单一职责：展示单个错题的缩略信息
//

import SwiftUI

// MARK: - Item Row

/// 错题列表行组件
///
/// 展示错题的缩略图、标题、学科、掌握度和日期信息。
///
/// ## 性能优化
///
/// - 使用 `AsyncImage` 风格的懒加载避免主线程阻塞
/// - 缓存解码后的缩略图到全局 ThumbnailCache
struct ItemRow: View {
    
    // MARK: - Properties
    
    /// 错题数据
    let reviewItem: ReviewItem
    
    /// 缓存的缩略图
    @State private var cachedThumbnail: UIImage?
    
    // MARK: - Constants
    
    private enum Layout {
        static let thumbnailSize: CGFloat = 70
        static let cornerRadius: CGFloat = 12
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            infoSection
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reviewItem.title), \(reviewItem.subject.displayName), \(reviewItem.mastery.displayName)")
        .task(id: reviewItem.id) {
            await loadThumbnail()
        }
    }
}

// MARK: - Thumbnail Loading

private extension ItemRow {
    
    /// 异步加载并缓存缩略图
    func loadThumbnail() async {
        // 1. 先检查全局缓存
        if let cached = ThumbnailCache.shared.thumbnail(for: reviewItem.id) {
            cachedThumbnail = cached
            return
        }
        
        // 2. 已有本地缓存或无数据则跳过
        guard cachedThumbnail == nil,
              let data = reviewItem.imageData else { return }
        
        // 3. 在后台线程解码和缩放图片
        let thumbnail = await Task.detached(priority: .userInitiated) {
            guard let original = UIImage(data: data) else { return nil as UIImage? }
            
            // 生成缩略图，避免加载全尺寸图片
            let targetSize = CGSize(width: Layout.thumbnailSize * 2, height: Layout.thumbnailSize * 2)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                original.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }.value
        
        await MainActor.run {
            if let thumbnail {
                ThumbnailCache.shared.setThumbnail(thumbnail, for: reviewItem.id)
                cachedThumbnail = thumbnail
            }
        }
    }
}

// MARK: - Subviews

private extension ItemRow {
    
    /// 缩略图
    @ViewBuilder
    var thumbnailView: some View {
        if let thumbnail = cachedThumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        } else if reviewItem.imageData != nil {
            loadingThumbnail
        } else {
            placeholderThumbnail
        }
    }
    
    /// 加载中的缩略图
    var loadingThumbnail: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color.gray.opacity(0.1))
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .overlay {
                ProgressView()
                    .scaleEffect(0.8)
            }
    }
    
    /// 占位缩略图
    var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color.gray.opacity(0.1))
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
    
    /// 信息区域
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reviewItem.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                subjectTag
                MasteryBadge(level: reviewItem.mastery)
                Spacer()
                dateLabel
            }
        }
    }
    
    /// 学科标签
    var subjectTag: some View {
        Text(reviewItem.subject.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(reviewItem.subject.color.opacity(0.1))
            .foregroundStyle(reviewItem.subject.color)
            .clipShape(Capsule())
    }
    
    /// 日期标签
    var dateLabel: some View {
        Text(reviewItem.createdAt, format: .dateTime.month().day())
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    List {
        // ItemRow requires a real ReviewItem, use mock in tests
        Text("ItemRow Preview - Requires ReviewItem")
    }
    .listStyle(.plain)
}
