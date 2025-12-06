//
//  LazyImageView.swift
//  NotBad
//
//  异步加载图片的 View - 从 ImageStorageService 按需加载
//

import SwiftUI

// MARK: - LazyImageView

/// 懒加载图片视图
///
/// 从文件系统按需加载图片，避免列表时加载所有图片到内存。
struct LazyImageView: View {
    
    /// 图片文件名
    let imagePath: String?
    
    /// 占位符
    var placeholder: Image = Image(systemName: "photo")
    
    /// 是否正在加载
    @State private var isLoading = true
    
    /// 加载的图片
    @State private var loadedImage: UIImage?
    
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
    
    @MainActor
    private func loadImage() async {
        guard let path = imagePath, !path.isEmpty else {
            isLoading = false
            return
        }
        
        // 后台加载
        loadedImage = await Task.detached {
            ImageStorageService.shared.load(fileName: path)
        }.value
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    LazyImageView(imagePath: nil)
        .frame(width: 200, height: 150)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
}
