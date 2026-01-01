//
//  CornerBracketShape.swift
//  NotBadFeatureCapture
//
//  Created by Yiming Liao on 2025/12/30.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  自定义 Shape，用于绘制相机取景器的四个角标。
//

import SwiftUI

struct CornerBracketShape: Shape {
    var cornerLength: CGFloat = 20
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Ensure corner length isn't too long
        let length = min(min(rect.width, rect.height) / 3, cornerLength)
        
        // Top Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        
        // Top Right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        
        // Bottom Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        
        // Bottom Left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        
        return path
    }
}
