//
//  MasteryBadge.swift
//  NotBad
//
//  掌握程度徽章组件
//

import SwiftUI

/// 掌握程度徽章样式
enum MasteryBadgeStyle {
    case compact     // 仅图标
    case standard    // 图标 + 名称
    case detailed    // 图标 + 详细描述
    case stars       // 星级显示
}

/// 掌握程度徽章
struct MasteryBadge: View {
    let level: MasteryLevel
    var style: MasteryBadgeStyle = .standard
    var showDetailText: Bool = false  // 向后兼容
    
    private var effectiveStyle: MasteryBadgeStyle {
        showDetailText ? .detailed : style
    }
    
    var body: some View {
        Group {
            switch effectiveStyle {
            case .compact:
                compactView
            case .standard:
                standardView
            case .detailed:
                detailedView
            case .stars:
                starsView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var compactView: some View {
        Image(systemName: level.icon)
            .font(.caption)
            .padding(6)
            .background(level.color.opacity(0.1))
            .foregroundStyle(level.color)
            .clipShape(Circle())
    }
    
    private var standardView: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
            Text(level.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
    }
    
    private var detailedView: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
            Text(level.detailText)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
    }
    
    private var starsView: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < level.stars ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(index < level.stars ? level.color : .gray.opacity(0.3))
            }
        }
    }
}

/// 带进度条的掌握程度显示
struct MasteryProgressView: View {
    let level: MasteryLevel
    var showLabel: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showLabel {
                HStack {
                    Text(level.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(level.progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(level.color.gradient)
                        .frame(width: geo.size.width * level.progress)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview("Badge Styles") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .compact)
            }
        }
        
        VStack(spacing: 8) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .standard)
            }
        }
        
        HStack(spacing: 12) {
            ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
                MasteryBadge(level: level, style: .stars)
            }
        }
    }
    .padding()
}

#Preview("Progress View") {
    VStack(spacing: 16) {
        ForEach(MasteryLevel.allCases, id: \.rawValue) { level in
            MasteryProgressView(level: level)
        }
    }
    .padding()
}
