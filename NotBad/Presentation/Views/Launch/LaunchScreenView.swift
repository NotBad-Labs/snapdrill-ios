//
//  LaunchScreenView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 启动屏幕视图
/// 专门负责启动时的UI展示
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.primary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("NotBad")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("错题本")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}