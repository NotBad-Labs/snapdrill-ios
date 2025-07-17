//
//  AdaptiveContainer.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  AdaptiveContainer.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct AdaptiveContainer<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat
    let horizontalPadding: CGFloat
    
    init(
        maxWidth: CGFloat = DeviceInfo.maxContentWidth,
        horizontalPadding: CGFloat = DeviceInfo.listPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, horizontalPadding)
    }
}