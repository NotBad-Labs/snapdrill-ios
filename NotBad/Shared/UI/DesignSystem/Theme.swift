//
//  Theme.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  Theme.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

@MainActor
@Observable
class Theme {
    // MARK: - Singleton
    static let shared = Theme()
    
    // MARK: - Theme Properties
    var isDarkMode: Bool = false
    var accentColor: Color = .blue
    var cornerRadius: CGFloat = .radiusM
    
    // MARK: - Private Init
    private init() {
        // 可以从 UserDefaults 加载主题设置
        loadThemeSettings()
    }
    
    // MARK: - Theme Methods
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveThemeSettings()
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
        saveThemeSettings()
    }
    
    // MARK: - Persistence
    private func loadThemeSettings() {
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        // 可以加载更多主题设置
    }
    
    private func saveThemeSettings() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        // 可以保存更多主题设置
    }
    
    // MARK: - Computed Properties
    var primaryBackground: Color {
        Color(.systemBackground)
    }
    
    var secondaryBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }
    
    var shadowColor: Color {
        Color.black.opacity(0.1)
    }
}
