//
//  LibraryComponents.swift
//  SnapDrillFeatureLibrary
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  题库模块共享的小组件，如 SubjectCapsule。
//

import SwiftUI
import SnapDrillData
import SnapDrillUI

// MARK: - Components

struct SubjectCapsule: View {
    let subject: SubjectModel
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: subject.icon)
            Text(subject.name)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color(hex: subject.colorHex) : Color(hex: subject.colorHex).opacity(0.1))
        .foregroundStyle(isSelected ? .white : Color(hex: subject.colorHex))
        .clipShape(Capsule())
        .animation(.spring, value: isSelected)
    }
}

#Preview {
    HStack {
        SubjectCapsule(subject: SubjectModel(name: "Math", icon: "function", colorHex: "#FF5733", sortOrder: 0), isSelected: true)
        SubjectCapsule(subject: SubjectModel(name: "Physics", icon: "atom", colorHex: "#33FF57", sortOrder: 1), isSelected: false)
    }
    .padding()
}
