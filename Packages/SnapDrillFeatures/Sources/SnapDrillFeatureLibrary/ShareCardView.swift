//
//  ShareCardView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题目分享卡片视图，用于生成可分享的题目卡片图片。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 分享卡片视图（用 ImageRenderer 渲染为图片）
nonisolated struct ShareCardView: View {

    let content: String?
    let image: UIImage?
    let subject: String
    let difficulty: Int
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 顶部品牌栏
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text(L10n.Library.shareCardTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // 题目图片
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 题目文字
            if let content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .lineSpacing(6)
                    .lineLimit(15)
            }

            // 元数据行
            HStack(spacing: 12) {
                // 学科
                Text(subject)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())

                // 难度星级
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= difficulty ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(level <= difficulty ? .orange : .gray.opacity(0.3))
                    }
                }

                Spacer()
            }

            // 标签
            if !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags.prefix(5), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
