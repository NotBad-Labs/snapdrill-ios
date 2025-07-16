//
//  HighlightedText.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct HighlightedText: View {
    let text: String
    let searchTerm: String
    let font: Font
    let highlightColor: Color
    
    init(
        text: String,
        searchTerm: String,
        font: Font = .body,
        highlightColor: Color = .yellow
    ) {
        self.text = text
        self.searchTerm = searchTerm
        self.font = font
        self.highlightColor = highlightColor
    }
    
    var body: some View {
        Text(TextHighlighter.highlight(
            text: text,
            searchTerm: searchTerm,
            highlightColor: highlightColor
        ))
        .font(font)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        HighlightedText(
            text: "这是一个数学题目",
            searchTerm: "数学",
            font: .headline
        )
        
        HighlightedText(
            text: "计算 3 + 5 × 2 = ?",
            searchTerm: "计算",
            font: .body
        )
    }
    .padding()
}