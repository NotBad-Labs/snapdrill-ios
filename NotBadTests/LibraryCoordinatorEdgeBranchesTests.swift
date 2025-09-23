import XCTest
@testable import NotBad

@MainActor
final class LibraryCoordinatorEdgeBranchesTests: XCTestCase {
    func testCoordinate_detailWithWrongModule_delegatesToParent() {
        let sut = LibraryCoordinator()
        let spy = ParentSpyCoordinator()
        sut.parent = spy
        sut.coordinate(to: .detail(module: "home", id: "id"))
        XCTAssertEqual(spy.receivedRoutes.count, 1)
    }

    func testCoordinate_defaultDelegatesUnknownRouteToParent() {
        let sut = LibraryCoordinator()
        let spy = ParentSpyCoordinator()
        sut.parent = spy
        sut.coordinate(to: .settings)
        XCTAssertEqual(spy.receivedRoutes, [.settings])
    }
}

@MainActor
private final class ParentSpyCoordinator: Coordinator {
    var receivedRoutes: [Route] = []
    var parent: (any Coordinator)?

    func start() {}
    func coordinate(to route: Route) { receivedRoutes.append(route) }
    func goBack() {}
    func delegate(route: Route) { receivedRoutes.append(route) }
}
