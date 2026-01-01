//
//  LibraryComponents.swift
//  NotBadFeatureLibrary
//
//  Created by NotBad Agent on 2025/12/31.
//

import SwiftUI
import NotBadData
import NotBadUI

// MARK: - Reusable Components

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
