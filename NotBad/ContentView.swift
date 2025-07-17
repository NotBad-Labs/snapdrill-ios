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
        TabView {
            QuestionListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("题库")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Question.self, inMemory: true)
}
