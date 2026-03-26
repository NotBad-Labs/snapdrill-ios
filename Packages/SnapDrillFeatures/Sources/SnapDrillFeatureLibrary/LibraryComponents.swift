//
//  LibraryComponents.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库模块共享的小组件，如 SubjectCapsule。
//

import SwiftUI
import SwiftData
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
        .accessibilityLabel(subject.name)
    }
}

#Preview {
    let schema = Schema([SubjectModel.self])
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let (math, physics): (SubjectModel, SubjectModel) = {
        let m = SubjectModel(name: "Math", icon: "function", colorHex: "#FF5733", sortOrder: 0)
        let p = SubjectModel(name: "Physics", icon: "atom", colorHex: "#33FF57", sortOrder: 1)
        container.mainContext.insert(m)
        container.mainContext.insert(p)
        return (m, p)
    }()

    HStack {
        SubjectCapsule(subject: math, isSelected: true)
        SubjectCapsule(subject: physics, isSelected: false)
    }
    .padding()
    .modelContainer(container)
}
