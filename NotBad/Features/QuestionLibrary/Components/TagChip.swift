//
//  TagChip.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct TagChip: View {
    let tag: String
    let searchTerm: String
    
    private var tagColor: Color {
        Color.tagColor(for: tag)
    }
    
    var body: some View {
        HighlightedText(
            text: tag,
            searchTerm: searchTerm,
            font: .labelSmall,
            highlightColor: .yellow
        )
        .padding(.horizontal, .spacingS)
        .padding(.vertical, .spacingXS)
        .background(tagColor.opacity(0.2))
        .foregroundColor(tagColor)
        .cornerRadius(.radiusS)
    }
}

#Preview {
    HStack {
        TagChip(tag: "数学", searchTerm: "")
        TagChip(tag: "英语", searchTerm: "")
        TagChip(tag: "物理", searchTerm: "")
        TagChip(tag: "化学", searchTerm: "")
    }
    .padding()
}