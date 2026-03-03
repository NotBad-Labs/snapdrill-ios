//
//  ResolvedExportSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  导出结果预览 Sheet，展示生成的 PDF 并提供分享功能。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// Helper to resolve IDs to Models for Export Sheet
struct ResolvedExportSheet: View {
    let ids: Set<UUID>
    @Environment(\.repositories) private var repositories
    @State private var resolvedItems: [ReviewExportSnapshot] = []

    var body: some View {
        ExportOptionsSheet(items: resolvedItems)
            .task {
                resolveItems()
            }
    }

    private func resolveItems() {
        do {
            self.resolvedItems = try repositories.review.fetchModels(by: ids).map { $0.toExportSnapshot() }
        } catch {
            SnapDrillLogger.generic.error("解析导出题目失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ResolvedExportSheet(ids: [])
}
