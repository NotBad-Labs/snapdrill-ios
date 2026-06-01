//
//  CaptureMetadataSection.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果页的分类信息 section：学科/来源下拉（含内联新建）+ 标签输入。
//  字段可见性由父 View 经 @AppStorage 读取后以 Bool 传入。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 采集结果页 — 分类信息 section
struct CaptureMetadataSection: View {
    @Bindable var viewModel: CaptureResultViewModel
    let showSubject: Bool
    let showSource: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.Capture.categoryInfo)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                // Subject — Menu label 仅覆盖右侧（当前值 + chevron），左侧标签始终可见
                // 支持内联新建：Things 3 / Notion / Apple Notes 均采用此模式
                if showSubject {
                    HStack {
                        Text(L10n.Capture.subject)
                            .foregroundStyle(.primary)
                        Spacer()
                        Menu {
                            ForEach(viewModel.availableSubjects) { subject in
                                Button {
                                    viewModel.selectedSubject = subject.name
                                } label: {
                                    Label(subject.name, systemImage: subject.icon)
                                }
                            }
                            Divider()
                            Button {
                                viewModel.showNewSubjectAlert = true
                            } label: {
                                Label(L10n.Capture.newSubject, systemImage: "plus")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedSubject)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding()
                }

                // Source — 同上：Menu label 仅右侧，保留内联新建
                if showSource {
                    if showSubject { Divider().padding(.leading) }
                    HStack {
                        Text(L10n.Capture.source)
                            .foregroundStyle(.primary)
                        Spacer()
                        Menu {
                            ForEach(viewModel.availableSources) { source in
                                Button {
                                    viewModel.selectedSource = source.name
                                } label: {
                                    Label(source.name, systemImage: source.icon)
                                }
                            }
                            Divider()
                            Button {
                                viewModel.showNewSourceAlert = true
                            } label: {
                                Label(L10n.Capture.newSource, systemImage: "plus")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.selectedSource)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding()
                }

                // Tags（始终可用，不可关闭）
                if showSubject || showSource { Divider().padding(.leading) }
                VStack(alignment: .leading) {
                    Text(L10n.Capture.tags)
                    TagInputView(
                        tags: $viewModel.tagList,
                        text: $viewModel.tagInputText,
                        suggestions: viewModel.availableTags.map { $0.name }
                    )
                }
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}
