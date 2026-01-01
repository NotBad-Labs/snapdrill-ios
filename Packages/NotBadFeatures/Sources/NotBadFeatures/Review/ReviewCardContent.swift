//
//  ReviewCardContent.swift
//  NotBadFeatures
//
//  Created by NotBad Architect on 2025/12/31.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  复习卡片的内容视图，展示题目和答案（翻转后）。
//

import SwiftUI
import NotBadData
import NotBadCore

/// 复习卡片的视觉内容，展示题目正文和（可选的）答案
/// 复习卡片正面：展示题目
struct ReviewCardFront: View {
    let item: ReviewItemModel
    
    @State private var showingEditSheet = false
    
    // User Preferences for Front Card
    @AppStorage("cardFrontAlignment") private var alignmentRaw: String = "center"
    @AppStorage("cardFrontFontSize") private var fontSizeRaw: Double = 32.0
    
    private var alignment: TextAlignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    // Computed alignment for frame (SwiftUI frame alignment is distinct from text alignment)
    private var frameAlignment: Alignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(item.content)
                .font(.system(size: fontSizeRaw, weight: .bold, design: .serif)) // Elegant Serif for main content
                .multilineTextAlignment(alignment)
                .lineSpacing(8)
                .padding(.horizontal, 24)
                .lineSpacing(8)
                .padding(.horizontal, 24)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Metadata Footer
            HStack(spacing: 8) {
                // Subject Badge
                Text(item.subject)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.8))
                    .clipShape(Capsule())
                
                // Difficulty Indicator (if set)
                if item.difficulty > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<item.difficulty, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                
                // Tags (Scrollable if many)
                if let tags = item.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(tags) { tag in
                                Text("#\(tag.name)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                // Ceramic Body: Explicitly Opaque
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground)) // Thicker, more opaque feel
                
                // Subtle Gloss Gradient (Ceramic Sheen)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Thin Border Ring
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
        )
        // Elegant Shadow (Floating Effect)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("编辑题目", systemImage: "pencil")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                    .padding(24)
                    .contentShape(Circle()) // Circular touch target for elegant highlight
            }
        }
        .compositingGroup()
        .sheet(isPresented: $showingEditSheet) {
            LibraryEditView(item: item)
        }
    }
}

/// 复习卡片背面：展示答案
struct ReviewCardBack: View {
    let item: ReviewItemModel
    
    // For loading answer image
    private let imageStorage = ImageStorage()
    
    @State private var showingEditSheet = false
    
    // User Preferences
    @AppStorage("cardContextAlignment") private var alignmentRaw: String = "leading"
    @AppStorage("cardContextFontSize") private var fontSizeRaw: Double = 16.0
    
    private var alignment: TextAlignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    // Computed alignment for frame
    private var frameAlignment: Alignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Question Context
            HStack(alignment: .top) {
                // Configurable Text
                // Configurable Text
                Text(item.content)
                    .font(.system(size: fontSizeRaw, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(alignment)
                    .lineLimit(3) // Allow a bit more context
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                
                // Edit Button (Fixed right)
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("编辑内容", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue.opacity(0.8))
                        .padding(12) // Slightly reduced padding for header context
                        .background(Color.clear) // Ensure touch registration
                        .contentShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .background(.quaternary)
                .padding(.horizontal, 24)
            
            // Body: Scrollable Answer
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.answerText)
                        .font(.system(size: 20, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                    
                    // Answer Image (if exists)
                    if let imagePath = item.answerImagePath,
                       let answerImage = imageStorage.loadImage(path: imagePath) {
                        Image(uiImage: answerImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                // Ceramic Body
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                
                // Subtle Gloss (slightly different for back)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                 
                // Border
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.1), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        .compositingGroup()
        .sheet(isPresented: $showingEditSheet) {
            LibraryEditView(item: item)
        }
    }
}

#Preview("Card Front") {
    ReviewCardFront(item: ReviewItemModel(content: "Explain the Heisenberg Uncertainty Principle."))
        .frame(height: 400)
        .padding()
}

#Preview("Card Back") {
    let item = ReviewItemModel(
        content: "Explain the Heisenberg Uncertainty Principle.",
        answerText: "The uncertainty principle states that we cannot know both the position and speed of a particle with perfect accuracy."
    )
    ReviewCardBack(item: item)
        .frame(height: 400)
        .padding()
}
