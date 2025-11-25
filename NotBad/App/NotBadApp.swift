//
//  NotBadApp.swift
//  NotBad
//
//  应用主入口
//

import SwiftUI
import SwiftData

/// NotBad 错题本应用主入口
@main
struct NotBadApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: ReviewItem.self)
    }
}
