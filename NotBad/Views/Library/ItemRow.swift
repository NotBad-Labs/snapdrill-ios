//
//  ItemRow.swift
//  NotBad
//
//  题目列表行视图
//

import SwiftUI

struct ItemRow: View {
    let item: ReviewItemModel
    
    var body: some View {
        HStack {
            // 缩略图
            thumbnailView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    subjectTag
                    
                    if item.needsReview {
                        Text("待复习")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // 掌握程度指示
            Circle()
                .fill(masteryColor)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayTitle), \(item.subjectRaw), 掌握程度\(item.masteryLevel)级")
    }
    
    // MARK: - Subviews
    
    private var thumbnailView: some View {
        Group {
            if let image = ImageStorageService.shared.load(fileName: item.imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }
    
    private var subjectTag: some View {
        Text(item.subjectRaw)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.blue.opacity(0.1))
            .clipShape(Capsule())
    }
    
    private var masteryColor: Color {
        switch item.masteryLevel {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .gray
        }
    }
}

#Preview {
    List {
        ItemRow(item: ReviewItemModel(title: "测试题目"))
    }
    .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
