//
//  ShareImageDownsampler.swift
//  SnapDrillShare
//
//  Created by NotBad Labs on 2026/04/20.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Share Extension OOM 防护：物理像素维度的图像降采样。
//

import UIKit
import ImageIO

/// 防 Share Extension OOM 的图像降采样工具。
///
/// Extension 内存预算约 120MB，5000x8000 原图解码后约 160MB，必然 OOM。
/// JPEG 编码前必须把长边压到 maxDimension 以内。
///
/// 关键：阈值判断与输出 renderer 都按**物理像素**计算（image.size 是 point，需乘 image.scale），
/// 与 `SnapDrillCore/ImageStorage.compressedJPEGData` SSOT 一致。
@MainActor
enum ShareImageDownsampler {
    private static let sourceOptions = [
        kCGImageSourceShouldCache: false
    ] as CFDictionary

    private static func thumbnailOptions(maxDimension: CGFloat) -> CFDictionary {
        [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ] as CFDictionary
    }

    /// 若图片**像素长边** ≤ maxDimension 直接返回原图，否则按比例缩到像素长边 = maxDimension。
    /// renderer 显式 `format.scale = 1` 确保 1 point = 1 pixel，避免屏幕 scale 二次放大。
    static func resizeIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let maxPixelSide = max(pixelWidth, pixelHeight)
        guard maxPixelSide > maxDimension else { return image }

        let ratio = maxDimension / maxPixelSide
        let newSize = CGSize(width: pixelWidth * ratio, height: pixelHeight * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func downsampledJPEGData(from url: URL, maxDimension: CGFloat, compressionQuality: CGFloat) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
        return downsampledJPEGData(from: source, maxDimension: maxDimension, compressionQuality: compressionQuality)
    }

    static func downsampledJPEGData(from data: Data, maxDimension: CGFloat, compressionQuality: CGFloat) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return downsampledJPEGData(from: source, maxDimension: maxDimension, compressionQuality: compressionQuality)
    }

    private static func downsampledJPEGData(
        from source: CGImageSource,
        maxDimension: CGFloat,
        compressionQuality: CGFloat
    ) -> Data? {
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions(maxDimension: maxDimension)
        ) else {
            return nil
        }

        return UIImage(cgImage: thumbnail).jpegData(compressionQuality: compressionQuality)
    }
}
