//
//  CaptureMetadataDefaultsTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureCapture

@Suite("Capture metadata defaults", .serialized)
@MainActor
struct CaptureMetadataDefaultsTests {

    @Test("D-META-A default form shows only category and secondary tags")
    func visibleDimensionsUseReleaseOneDefaults() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repositories = RepositoryContainer(modelContext: container.mainContext)
        let dimensions = [
            CategoryDimensionModel(
                name: "分类", isBuiltIn: true, systemKey: CategorySystemKey.category, sortOrder: 0
            ),
            CategoryDimensionModel(
                name: "来源", isBuiltIn: true, systemKey: CategorySystemKey.source, sortOrder: 1
            ),
            CategoryDimensionModel(
                name: "级别", isBuiltIn: true, systemKey: CategorySystemKey.level, sortOrder: 2
            ),
            CategoryDimensionModel(
                name: "标签", isMultiValue: true, isBuiltIn: true,
                systemKey: CategorySystemKey.tag, sortOrder: 3
            )
        ]
        for dimension in dimensions {
            UserDefaults.standard.removeObject(forKey: dimension.captureVisibilityKey)
            try repositories.dimension.insertAndSave(dimension)
        }
        defer {
            for dimension in dimensions {
                UserDefaults.standard.removeObject(forKey: dimension.captureVisibilityKey)
            }
        }

        let viewModel = CaptureResultViewModel(
            content: "",
            image: nil,
            draftToken: nil,
            repositories: repositories,
            ocrService: MockOCRServiceShared(),
            analyticsService: AnalyticsServiceMock(),
            contentTaggingService: ContentTaggingServiceMock(),
            router: CaptureRouter(),
            draftService: CaptureDraftServiceMock(),
            activityTracker: AppActivityTracker()
        )
        viewModel.loadFormData()

        #expect(viewModel.visibleDimensionInputModels().map(\.title) == ["分类", "标签"])
    }
}
