//
//  FlipView.swift
//  SnapDrillUI
//
//  Created by SnapDrill Labs on 2026/01/01.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  通用的 3D 翻转卡片容器，支持点击翻转动画。
//

import SwiftUI

/// 通用的 3D 翻转卡片容器
public struct FlipView<Front: View, Back: View>: View {
    var isFlipped: Bool
    var front: () -> Front
    var back: () -> Back
    
    public init(
        isFlipped: Bool,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.isFlipped = isFlipped
        self.front = front
        self.back = back
    }
    
    public var body: some View {
        ZStack {
            front()
                .modifier(FlipOpacity(percentage: isFlipped ? 0 : 1))
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
            
            back()
                .modifier(FlipOpacity(percentage: isFlipped ? 1 : 0))
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
        }
    }
}

/// Helper modifier to handle opacity during flip
private struct FlipOpacity: ViewModifier, @preconcurrency Animatable {
    var percentage: CGFloat
    
    var animatableData: CGFloat {
        get { percentage }
        set { percentage = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(Double(percentage > 0.5 ? 1 : 0))
    }
}

#Preview {
    @Previewable @State var isFlipped = false
    return VStack(spacing: 40) {
        FlipView(
            isFlipped: isFlipped,
            front: {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue.gradient)
                    .frame(width: 300, height: 200)
                    .overlay(Text("Front Side").foregroundColor(.white).font(.title))
            },
            back: {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.orange.gradient)
                    .frame(width: 300, height: 200)
                    .overlay(Text("Back Side").foregroundColor(.white).font(.title))
            }
        )
        
        Button("Flip Card") {
            withAnimation(.spring()) {
                isFlipped.toggle()
            }
        }
    }
}
