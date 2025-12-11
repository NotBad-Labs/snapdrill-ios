import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
#endif

// MARK: - Platform Image Extensions

extension PlatformImage {
    /// 转换为 PNG Data
    var pngData: Data? {
        #if canImport(UIKit)
        return self.pngData()
        #elseif canImport(AppKit)
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }
    
    /// 从 Data 创建图片
    static func from(data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #endif
    }
}
