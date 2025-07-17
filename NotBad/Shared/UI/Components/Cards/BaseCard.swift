//
//  BaseCard.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  BaseCard.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct BaseCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = .cardPadding
    var backgroundColor: Color? = nil
    var cornerRadius: CGFloat = .radiusM
    var shadowRadius: CGFloat = 2
    var shadowOpacity: Double = 0.1
    
    init(
        padding: CGFloat = .cardPadding,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = .radiusM,
        shadowRadius: CGFloat = 2,
        shadowOpacity: Double = 0.1,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor ?? Theme.shared.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: Theme.shared.shadowColor,
                radius: shadowRadius,
                x: 0,
                y: 1
            )
    }
}

#Preview {
    VStack(spacing: .spacingM) {
        BaseCard {
            VStack(alignment: .leading) {
                Text("题目内容")
                    .font(.headingSmall)
                Text("这是一个示例题目")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
            }
        }
        
        BaseCard(backgroundColor: .blue.opacity(0.1)) {
            Text("彩色卡片示例")
                .font(.bodyMedium)
        }
    }
    .padding()
}
