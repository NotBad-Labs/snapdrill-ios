//
//  ResolvedExportSheet.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  导出结果预览 Sheet，展示生成的 PDF 并提供分享功能。
//

import SwiftUI
import SnapDrillCore
import SwiftData
import SnapDrillData

/// Helper to resolve IDs to Models for Export Sheet
struct ResolvedExportSheet: View {
    let ids: Set<ReviewItemModel.ID>
    @Environment(\.modelContext) private var modelContext
    @State private var resolvedItems: [ReviewItemModel] = []
    
    var body: some View {
        ExportOptionsSheet(items: resolvedItems)
            .task {
                resolveItems()
            }
    }
    
    private func resolveItems() {
        // Fetch all items with IDs
        // Predicate with array contains is tricky in SwiftData currently?
        // Let's try simple fetch and filter memory if list is small, or loop fetches.
        // Or if we can construct valid predicate.
        // Safer: map IDs to fetch one by one or fetch all and filter.
        // Given we are in a sheet, fetching all might be overkill.
        // But SwiftData `PersistentIdentifier` is not what we have, we have UUIDs.
        
        // Strategy: Fetch all items matching IDs.
        // Since we can't easily do `ids.contains($0.id)` in Predicate yet (Swift 6 strictness/macros limitations),
        // we will fetch all (Library is usually < 10000 items, and we assume optimized local DB)
        // OR better: The correct way is `id` IN `ids`.
        // Let's try to construct a predicate if possible.
        // Or fallback: Fetch all items and filter in memory.
        
        do {
            let descriptor = FetchDescriptor<ReviewItemModel>()
            let allItems = try modelContext.fetch(descriptor)
            self.resolvedItems = allItems.filter { ids.contains($0.id) }
        } catch {
            SnapDrillLogger.generic.info("Failed to resolve export items: \(error)")
        }
    }
}

#Preview {
    ResolvedExportSheet(ids: [])
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
