//
//  MasteryBadge.swift
//  NotBad
//
//  掌握程度徽章组件
//

import SwiftUI

/// 掌握程度徽章
struct MasteryBadge: View {
    let level: MasteryLevel
    var showDetailText: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
            Text(showDetailText ? level.detailText : level.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
            MasteryBadge(level: level)
        }
    }
}
