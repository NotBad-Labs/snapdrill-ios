//
//  ReviewCardContent.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习卡片的内容视图，展示题目和答案（翻转后）。
//

import SwiftUI
import SnapDrillDomain
import SnapDrillCore

/// 复习卡片的视觉内容，展示题目正文和（可选的）答案
/// 复习卡片正面：展示题目
struct ReviewCardFront: View {
    
    // MARK: - Properties
    
    let item: ReviewItem
    
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
    
    private var frameAlignment: Alignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(item.content ?? "")
                .font(.system(size: fontSizeRaw, weight: .bold, design: .serif))
                .multilineTextAlignment(alignment)
                .lineSpacing(8)
                .padding(.horizontal, 24)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
            
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
                
                // Difficulty Indicator
                if item.difficulty.starCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<item.difficulty.starCount, id: \.self) { _ in
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
                
                // Tags
                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text("#\(tag)")
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
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
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
                    .contentShape(Circle())
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            LibraryEditView(item: item)
        }
    }
}

/// 复习卡片背面：展示答案
struct ReviewCardBack: View {
    
    // MARK: - Properties
    
    let item: ReviewItem
    
    private let imageStorage = ImageStorage()
    
    @State private var showingEditSheet = false
    @State private var loadedImage: UIImage?
    
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
    
    private var frameAlignment: Alignment {
        switch alignmentRaw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text(item.content ?? "")
                    .font(.system(size: fontSizeRaw, weight: .medium, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(alignment)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
                
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
                        .padding(12)
                        .contentShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .background(.quaternary)
                .padding(.horizontal, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let answerText = item.answerText {
                        Text(answerText)
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                    }
                    
                    if let imagePath = item.answerImagePath {
                        if let uiImage = loadedImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 150)
                                .overlay(ProgressView())
                                .task {
                                    await loadImageAsync(path: imagePath)
                                }
                        }
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                 
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.1), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        .sheet(isPresented: $showingEditSheet) {
            LibraryEditView(item: item)
        }
    }
    
    private func loadImageAsync(path: String) async {
        let image = await Task.detached(priority: .userInitiated) {
            imageStorage.loadImage(path: path)
        }.value
        
        withAnimation(.easeOut(duration: 0.2)) {
            self.loadedImage = image
        }
    }
}

#Preview("Card Front") {
    ReviewCardFront(item: ReviewItem(id: UUID(), content: "Explain the Heisenberg Uncertainty Principle.", subject: "Physics"))
        .frame(height: 400)
        .padding()
}

#Preview("Card Back") {
    ReviewCardBack(item: ReviewItem(id: UUID(), content: "Explain the Heisenberg Uncertainty Principle.", answerText: "Position and speed cannot both be known perfectly."))
        .frame(height: 400)
        .padding()
}
