//
//  ContentView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding()

            Text("NotBad 错题本")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("文档驱动开发示例项目")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding()

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
