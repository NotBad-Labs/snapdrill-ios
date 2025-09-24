//
//  ContentAndTabsRenderingTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/23/25.
//

import XCTest
import SwiftUI
@testable import NotBad

@MainActor
final class ContentAndTabsRenderingTests: XCTestCase {
    func testContentView_Renders_InDarkMode_NoCrash() {
        let view = ContentView()
        let hosting = UIHostingController(rootView: view)
        hosting.loadViewIfNeeded()
        hosting.overrideUserInterfaceStyle = .dark
        // Trigger relayout to exercise color/trait changes
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        XCTAssertNotNil(hosting.view)
    }

    func testMainTabView_TabSwitches_NoCrash() {
        let main = MainCoordinator()
        let appEnv = AppEnvironment.createTestEnvironment()
        let tabView = MainTabView(coordinator: main).withAppEnvironment(appEnv)
        let hosting = UIHostingController(rootView: tabView)
        hosting.loadViewIfNeeded()

        // Switch across all tabs and ensure no crash while the view updates.
        for idx in 0...4 {
            main.selectedTab = idx
            // Allow SwiftUI to process state change
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
            hosting.view.setNeedsLayout()
            hosting.view.layoutIfNeeded()
            XCTAssertEqual(main.selectedTab, idx)
        }
    }
}
