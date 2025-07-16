//
//  DifficultyBadge.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct DifficultyBadge: View {
    let difficulty: Int
    
    private var difficultyText: String {
        switch difficulty {
        case 1: return "基础题"
        case 2: return "简单题"
        case 3: return "中等题"
        case 4: return "困难题"
        case 5: return "极难题"
        default: return "中等题"
        }
    }
    
    private var difficultyColor: Color {
        Color.difficultyColor(for: difficulty)
    }
    
    var body: some View {
        Text(difficultyText)
            .font(.labelSmall)
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingXS)
            .background(difficultyColor.opacity(0.2))
            .foregroundColor(difficultyColor)
            .cornerRadius(.radiusS)
    }
}

#Preview {
    HStack {
        DifficultyBadge(difficulty: 1)
        DifficultyBadge(difficulty: 2)
        DifficultyBadge(difficulty: 3)
        DifficultyBadge(difficulty: 4)
        DifficultyBadge(difficulty: 5)
    }
    .padding()
}