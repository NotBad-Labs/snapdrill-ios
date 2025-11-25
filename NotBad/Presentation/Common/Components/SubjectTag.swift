//
//  SubjectTag.swift
//  NotBad
//
//  学科标签组件
//

import SwiftUI

/// 学科标签样式
enum SubjectTagStyle {
    case compact   // 紧凑：仅显示名称
    case standard  // 标准：图标 + 名称
    case detailed  // 详细：图标 + 名称 + 数量
}

/// 学科标签组件
struct SubjectTag: View {
    let subject: Subject
    var style: SubjectTagStyle = .standard
    var count: Int?
    var isSelected: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            if style != .compact {
                Image(systemName: subject.icon)
                    .font(.caption)
            }
            
            Text(subject.displayName)
                .font(style == .compact ? .caption2 : .caption)
                .fontWeight(isSelected ? .semibold : .regular)
            
            if style == .detailed, let count {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? .white.opacity(0.3) : subject.color.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, style == .compact ? 8 : 12)
        .padding(.vertical, style == .compact ? 4 : 6)
        .background(
            isSelected ?
            AnyShapeStyle(subject.color.gradient) :
            AnyShapeStyle(subject.color.opacity(0.1))
        )
        .foregroundStyle(isSelected ? .white : subject.color)
        .clipShape(Capsule())
        .shadow(
            color: isSelected ? subject.color.opacity(0.3) : .clear,
            radius: 4, y: 2
        )
    }
}

/// 可选择的学科标签
struct SelectableSubjectTag: View {
    let subject: Subject
    @Binding var isSelected: Bool
    var count: Int?
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isSelected.toggle()
            }
        } label: {
            SubjectTag(
                subject: subject,
                style: count != nil ? .detailed : .standard,
                count: count,
                isSelected: isSelected
            )
        }
    }
}

#Preview("Subject Tags") {
    VStack(spacing: 16) {
        // Compact
        HStack {
            ForEach(Subject.coreSubjects, id: \.self) { subject in
                SubjectTag(subject: subject, style: .compact)
            }
        }
        
        // Standard
        HStack {
            ForEach(Subject.coreSubjects, id: \.self) { subject in
                SubjectTag(subject: subject, style: .standard)
            }
        }
        
        // Detailed
        HStack {
            SubjectTag(subject: .math, style: .detailed, count: 15)
            SubjectTag(subject: .chinese, style: .detailed, count: 8)
            SubjectTag(subject: .english, style: .detailed, count: 12)
        }
        
        // Selected
        HStack {
            SubjectTag(subject: .math, style: .standard, isSelected: true)
            SubjectTag(subject: .physics, style: .standard, isSelected: false)
        }
    }
    .padding()
}
