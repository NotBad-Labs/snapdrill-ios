//
//  ContentView.swift
//  NotBad
//
//  Created by YIMING LIAO on 8/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ReviewItemListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
