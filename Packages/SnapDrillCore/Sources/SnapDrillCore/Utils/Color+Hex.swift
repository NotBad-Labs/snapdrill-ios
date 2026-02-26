//
//  Color+Hex.swift
//  SnapDrillUtils
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  Color 扩展，提供十六进制颜色初始化功能。
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
extension Color {
    /// Initialize Color from Hex string (e.g. "#FF5733" or "FF5733")
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Convert Color to Hex string (e.g. "#FF5733")
    public func toHex() -> String? {
        #if canImport(UIKit)
        let color = UIColor(self)
        #elseif canImport(AppKit)
        let color = NSColor(self)
        #else
        return nil
        #endif
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        #if canImport(UIKit)
        let success = color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif canImport(AppKit)
        let success = color.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha) != nil
        #else
        let success = false
        #endif
        
        guard success else {
            return nil
        }
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
