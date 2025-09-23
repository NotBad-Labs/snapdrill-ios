// NotBadTests/CoordinatorBaseTests.swift
// Covers BaseCoordinator default behaviors: start/goBack/delegate/coordinate

import XCTest
@testable import NotBad

@MainActor
final class CoordinatorBaseTests: XCTestCase {

    // Minimal parent spy implementing Coordinator to capture delegated routes
    final class ParentSpy: Coordinator {
        var parent: (any Coordinator)?
        private(set) var receivedRoutes: [Route] = []

        func start() { /* no-op */ }
        func coordinate(to route: Route) { receivedRoutes.append(route) }
        func goBack() { /* no-op */ }
        func delegate(route: Route) { receivedRoutes.append(route) }
    }

    func testStart_resetsNavigationPathToEmpty() {
        // Given
        let sut = BaseCoordinator()
    sut.navigationPath.append(Route.home)
    sut.navigationPath.append(Route.library)
        XCTAssertFalse(sut.navigationPath.isEmpty)

        // When
        sut.start()

        // Then
        XCTAssertTrue(sut.navigationPath.isEmpty, "start() should reset navigation path")
    }

    func testGoBack_onEmptyPath_doesNothing() {
        // Given
        let sut = BaseCoordinator()
        XCTAssertTrue(sut.navigationPath.isEmpty)

        // When
        sut.goBack()

        // Then
        XCTAssertTrue(sut.navigationPath.isEmpty, "goBack on empty path should be a no-op")
    }

    func testGoBack_removesLastWhenNotEmpty() {
        // Given
        let sut = BaseCoordinator()
    sut.navigationPath.append(Route.home)
    sut.navigationPath.append(Route.detail(module: "lib", id: "1"))
        XCTAssertEqual(sut.navigationPath.count, 2)

        // When
        sut.goBack()

        // Then
        XCTAssertEqual(sut.navigationPath.count, 1)
    }

    func testCoordinate_defaultDelegatesToParent() {
        // Given
        let sut = BaseCoordinator()
        let parent = ParentSpy()
        sut.parent = parent

        // When
        sut.coordinate(to: .settings)

        // Then: Parent should have received the route via delegation
        XCTAssertEqual(parent.receivedRoutes, [.settings])
    }

    func testDelegate_forwardsRouteToParent() {
        // Given
        let sut = BaseCoordinator()
        let parent = ParentSpy()
        sut.parent = parent

        // When
        sut.delegate(route: .about)

        // Then
        XCTAssertEqual(parent.receivedRoutes, [.about])
    }
}
