//
//  Colors.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors
    static let primaryBlue = Color("PrimaryBlue")
    static let primaryGreen = Color("PrimaryGreen")
    static let primaryRed = Color("PrimaryRed")
    static let primaryOrange = Color("PrimaryOrange")
    
    // MARK: - Background Colors (使用系统颜色)
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.systemGroupedBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    // MARK: - Text Colors (使用系统颜色)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.6)
    
    // MARK: - Difficulty Colors
    static let difficultyEasy = Color.green
    static let difficultyMedium = Color.orange
    static let difficultyHard = Color.red
    
    // MARK: - Status Colors
    static let statusReviewed = Color.green
    static let statusPending = Color.orange
    static let statusError = Color.red
    
    // MARK: - Tag Colors
    static let tagMath = Color.blue
    static let tagEnglish = Color.purple
    static let tagPhysics = Color.cyan
    static let tagChemistry = Color.green
    static let tagDefault = Color.gray
    
    // MARK: - Helper Methods
    static func difficultyColor(for difficulty: Int) -> Color {
        switch difficulty {
        case 1...2: return .difficultyEasy
        case 3: return .difficultyMedium
        case 4...5: return .difficultyHard
        default: return .difficultyMedium
        }
    }
    
    static func tagColor(for tag: String) -> Color {
        switch tag {
        case "数学": return .tagMath
        case "英语", "外语": return .tagEnglish
        case "物理": return .tagPhysics
        case "化学": return .tagChemistry
        default: return .tagDefault
        }
    }
}
