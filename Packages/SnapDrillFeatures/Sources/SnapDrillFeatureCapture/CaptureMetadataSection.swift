//
//  CaptureMetadataSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的分类信息 section：动态渲染所有可见维度（DimensionInputRow）。
//  L3：取代固定的学科/来源 Menu + 标签输入；可见性按维度（VM.isDimensionVisible）。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 采集结果页 — 分类信息 section（动态维度）
struct CaptureMetadataSection: View {
    @Bindable var viewModel: CaptureResultViewModel

    var body: some View {
        let models = viewModel.visibleDimensionInputModels()
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.Capture.categoryInfo)
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 0) {
                    ForEach(Array(models.enumerated()), id: \.element.id) { index, model in
                        if index > 0 { Divider().padding(.leading) }
                        DimensionInputRow(
                            model: model,
                            selectedIds: viewModel.selectedIds(forDimension: model.id),
                            onToggle: { viewModel.toggleValue($0, inDimension: model.id) },
                            onCreateValue: { viewModel.createValue(name: $0, inDimension: model.id) }
                        )
                        .padding()
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}
