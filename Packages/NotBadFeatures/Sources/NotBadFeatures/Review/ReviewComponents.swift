//
//  ReviewComponents.swift
//  NotBadFeatures
//
//  Created by NotBad Agent on 2025/12/31.
//

import SwiftUI
import UIKit
import NotBadCore
import NotBadData

// MARK: - Swipe Card Wrapper (Physics Engine)
struct SwipeCard<Content: View>: View {
    let content: Content
    let onRemove: (Int) -> Void // -1 for Left (Next), 1 for Right (Prev/Forget)
    
    @State private var translation: CGSize = .zero
    
    // Config
    private let threshold: CGFloat = 100
    private let rotationDegrees: Double = 15
    
    init(@ViewBuilder content: () -> Content, onRemove: @escaping (Int) -> Void) {
        self.content = content()
        self.onRemove = onRemove
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: translation.width, y: translation.height)
                .rotationEffect(.degrees(geometry.size.width > 0 ? Double(translation.width / geometry.size.width) * rotationDegrees : 0))
                .simultaneousGesture( // Use simultaneous to coexist with ScrollView
                    DragGesture()
                        .onChanged { gesture in
                            // Directional Lock:
                            // If user is scrolling vertically (dy > dx), let ScrollView handle it.
                            // We only move the card if the gesture is primarily horizontal.
                            if abs(gesture.translation.height) > abs(gesture.translation.width) {
                                // If we are already moving significantly, maybe allow it?
                                // But for stability, let's prioritize scrolling.
                                // Don't update translation (effectively locking card).
                                return
                            }
                            
                            translation = gesture.translation
                        }
                        .onEnded { gesture in
                            let width = geometry.size.width
                            let velocity = gesture.predictedEndLocation.x - gesture.startLocation.x
                            
                            // Check if the card was actually moved (filter out vertical scroll endings)
                            if translation == .zero { return }
                            
                            if gesture.translation.width < -threshold || velocity < -500 {
                                // Swipe Left
                                snapAway(direction: -1, width: width)
                            } else if gesture.translation.width > threshold || velocity > 500 {
                                // Swipe Right
                                snapAway(direction: 1, width: width)
                            } else {
                                // Reset
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    translation = .zero
                                }
                            }
                        }
                )
        }
    }
    
    private func snapAway(direction: Int, width: CGFloat) {
        let targetX = CGFloat(direction) * width * 2
        let targetY = translation.height + 50 // Slight drop
        
        withAnimation(.easeOut(duration: 0.3)) {
            translation = CGSize(width: targetX, height: targetY)
        }
        
        // Notify removal after animation starts (visual only, logical removal happens in parent)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onRemove(direction)
        }
    }
}

// MARK: - Visual Card Content
struct ReviewCardContent: View {
    let item: ReviewItemModel
    let isAnswerShown: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Text(item.content)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.leading) // Better for mixed length
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !item.answerText.isEmpty && isAnswerShown {
                        Divider()
                        
                        Text(item.answerText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .frame(minHeight: 300, alignment: .center) // Minimum height to keep short text centered? No, top is fine.
            }
            // Limit the ScrollView height to avoid taking full screen if not needed, 
            // but here we are in a fixed card size.
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .padding(.horizontal)         // Outer margin
        .padding(.vertical, 40)       // Vertical margin for stack look
    }
}

// MARK: - Background
struct ReviewBackground: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
            GeometryReader { proxy in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -50, y: -50)
                
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: proxy.size.width - 200, y: 100)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Header
struct ReviewProgressHeader: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack {
            Text("进度")
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(current)")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("/ \(total)")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
    }
}

// MARK: - Empty State
struct ReviewEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .symbolEffect(.bounce, value: true)
            
            Text(title)
                .font(.title2.bold())
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
