//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 9/20/25.
//

import SwiftUI

@main
struct NotBadApp: App {
    var body: some Scene {
        WindowGroup {
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
}
