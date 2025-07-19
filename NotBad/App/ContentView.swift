//
//  ContentView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Question.self, inMemory: true)
}