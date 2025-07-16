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
        isDarkMode ? Color.black : Color.white
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05)
    }
    
    var cardBackground: Color {
        isDarkMode ? Color.gray.opacity(0.15) : Color.white
    }
    
    var shadowColor: Color {
        isDarkMode ? Color.clear : Color.black.opacity(0.1)
    }
}