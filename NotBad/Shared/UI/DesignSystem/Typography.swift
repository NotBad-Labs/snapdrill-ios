//
//  Typography.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

extension Font {
    // MARK: - Headings
    static let headingLarge = Font.system(size: 28, weight: .bold, design: .default)
    static let headingMedium = Font.system(size: 22, weight: .semibold, design: .default)
    static let headingSmall = Font.system(size: 18, weight: .medium, design: .default)
    
    // MARK: - Body Text
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Labels
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Special
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let footnote = Font.system(size: 10, weight: .regular, design: .default)
}
