//
//  NotBadApp.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData

// MARK: - NotBadApp

/// NotBad K12 错题本应用主入口
@main
struct NotBadApp: App {
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: ReviewItem.self)
    }
}
