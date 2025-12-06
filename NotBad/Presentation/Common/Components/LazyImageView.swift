//
//  LazyImageView.swift
//  NotBad
//
//  异步加载图片的 View - 从 ImageRepository 按需加载
//

import SwiftUI
import OSLog

// MARK: - LazyImageView

/// 懒加载图片视图
///
/// 从 ImageRepository 按需加载图片，避免列表时加载所有图片到内存。
///
/// ## 使用示例
///
/// ```swift
/// LazyImageView(reviewItemId: item.id)
///     .frame(maxHeight: 200)
///     .cornerRadius(12)
/// ```
struct LazyImageView: View {
    
    // MARK: - Properties
    
    /// ReviewItem ID
    let reviewItemId: UUID
    
    /// 占位符
    var placeholder: Image = Image(systemName: "photo")
    
    /// 是否正在加载
    @State private var isLoading = true
    
    /// 加载的图片
    @State private var loadedImage: UIImage?
    
    /// 图片仓库
    @Environment(\.imageRepository) private var imageRepository
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                placeholder
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadImage() async {
        guard let imageRepo = imageRepository else {
            isLoading = false
            return
        }
        
        if let imageData = imageRepo.loadImage(for: reviewItemId),
           let uiImage = UIImage(data: imageData) {
            loadedImage = uiImage
        }
        
        isLoading = false
    }
}

// MARK: - Environment Key

private struct ImageRepositoryKey: EnvironmentKey {
    static let defaultValue: ImageRepositoryProtocol? = nil
}

extension EnvironmentValues {
    var imageRepository: ImageRepositoryProtocol? {
        get { self[ImageRepositoryKey.self] }
        set { self[ImageRepositoryKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// 注入图片仓库
    func withImageRepository(_ repository: ImageRepositoryProtocol) -> some View {
        environment(\.imageRepository, repository)
    }
}

// MARK: - Preview

#Preview {
    LazyImageView(reviewItemId: UUID())
        .frame(width: 200, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
}
