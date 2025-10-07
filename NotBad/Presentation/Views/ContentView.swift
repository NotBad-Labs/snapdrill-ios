//
//  ContentView.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI
import SwiftData

/// 主内容视图
///
/// 职责：
/// - 应用主界面展示
/// - 导航管理
/// - 视图协调
@MainActor
struct ContentView: View {
    
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            WelcomeView()
                .navigationTitle("NotBad")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [], inMemory: true)
}
