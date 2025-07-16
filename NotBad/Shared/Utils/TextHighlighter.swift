//
//  TextHighlighter.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftUI

struct TextHighlighter {
    static func highlight(
        text: String,
        searchTerm: String,
        highlightColor: Color = .yellow,
        highlightOpacity: Double = 0.3
    ) -> AttributedString {
        
        guard !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return AttributedString(text)
        }
        
        var attributedString = AttributedString(text)
        let lowercasedText = text.lowercased()
        let lowercasedSearchTerm = searchTerm.lowercased()
        
        // 查找所有匹配的范围
        var searchRange = lowercasedText.startIndex
        
        while searchRange < lowercasedText.endIndex {
            if let range = lowercasedText.range(of: lowercasedSearchTerm, range: searchRange..<lowercasedText.endIndex) {
                
                // 转换为 AttributedString 的范围
                let attributedRange = Range(range, in: attributedString)!
                
                // 应用高亮样式
                attributedString[attributedRange].backgroundColor = highlightColor.opacity(highlightOpacity)
                attributedString[attributedRange].foregroundColor = .primary
                
                // 继续搜索下一个匹配
                searchRange = range.upperBound
            } else {
                break
            }
        }
        
        return attributedString
    }
}