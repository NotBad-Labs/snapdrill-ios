//
//  CoordinatorNavigationTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

@MainActor
final class CoordinatorNavigationTests: XCTestCase {
    func testHomeCoordinator_TypedRoutePushAndReset() {
        let coordinator = HomeCoordinator()
        coordinator.start()
        XCTAssertEqual(coordinator.navigationPath.count, 0)

        coordinator.coordinate(to: .detail(module: "home", id: "123"))
        XCTAssertEqual(coordinator.navigationPath.count, 1)

        coordinator.coordinate(to: .home)
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testDiscoveryCoordinator_TypedRoutePushAndReset() {
        let coordinator = DiscoveryCoordinator()
        coordinator.start()
        XCTAssertEqual(coordinator.navigationPath.count, 0)

        coordinator.coordinate(to: .detail(module: "discovery", id: "abc"))
        XCTAssertEqual(coordinator.navigationPath.count, 1)

        coordinator.coordinate(to: .discovery)
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testProfileCoordinator_SettingsAboutDetailAndReset() {
        let coordinator = ProfileCoordinator()
        coordinator.start()
        XCTAssertEqual(coordinator.navigationPath.count, 0)

        coordinator.coordinate(to: .settings)
        XCTAssertEqual(coordinator.navigationPath.count, 1)

        coordinator.coordinate(to: .about)
        XCTAssertEqual(coordinator.navigationPath.count, 2)

        coordinator.coordinate(to: .detail(module: "profile", id: "xyz"))
        XCTAssertEqual(coordinator.navigationPath.count, 3)

        coordinator.coordinate(to: .profile)
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testLibraryCoordinator_DetailPracticeAndReset() {
        let coordinator = LibraryCoordinator()
        coordinator.start()
        XCTAssertEqual(coordinator.navigationPath.count, 0)

        coordinator.coordinate(to: .detail(module: "library", id: "item-1"))
        XCTAssertEqual(coordinator.navigationPath.count, 1)

        coordinator.coordinate(to: .practiceMode)
        XCTAssertEqual(coordinator.navigationPath.count, 2)

        coordinator.coordinate(to: .library)
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
}

@MainActor
final class MainCoordinatorCrossTabTests: XCTestCase {
    func testNavigateToLibraryFromHome_ResetsLibraryPathAndSwitchesTab() {
        let main = MainCoordinator()
        main.start()
        XCTAssertEqual(main.selectedTab, 0)

        // Pre-populate library path
        main.libraryCoordinator.coordinate(to: .detail(module: "library", id: "abc"))
        XCTAssertEqual(main.libraryCoordinator.navigationPath.count, 1)

        // Trigger cross-tab navigation
        main.coordinate(to: .navigateToLibraryFromHome)

        XCTAssertEqual(main.selectedTab, 1)
        XCTAssertEqual(main.libraryCoordinator.navigationPath.count, 0)
    }

    func testNavigateToPracticeFromLibrary_PushesPractice() {
        let main = MainCoordinator()
        main.start()

        // Ensure on Library tab
        main.coordinate(to: .library)
        XCTAssertEqual(main.selectedTab, 1)
        XCTAssertEqual(main.libraryCoordinator.navigationPath.count, 0)

        // Trigger practice navigation
        main.coordinate(to: .navigateToPracticeFromLibrary)

        XCTAssertEqual(main.selectedTab, 1)
        XCTAssertEqual(main.libraryCoordinator.navigationPath.count, 1)
    }
}
