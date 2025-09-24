//
//  SnapshotTemplateTests.swift
//  NotBadTests
//
//  This file demonstrates how to write snapshot tests using the
//  'pointfreeco/swift-snapshot-testing' library, but it's fully
//  optional and compiles without the dependency.
//

import XCTest

#if canImport(SnapshotTesting)
import SnapshotTesting
@testable import NotBad

final class SnapshotTemplateTests: XCTestCase {
    override func setUp() async throws {
        // Record mode off by default. Enable to generate baselines when needed.
        isRecording = false
    }

    func testLibraryView_DefaultLayout_iPhone13() {
        let coordinator = LibraryCoordinator()
        let mockService = ReviewItemService(repository: InMemoryReviewItemRepository())
        let vm = LibraryViewModel(reviewItemService: mockService, coordinator: coordinator)
        let view = LibraryView(viewModel: vm, coordinator: coordinator)
            .withAppEnvironment()

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }
}
#endif
