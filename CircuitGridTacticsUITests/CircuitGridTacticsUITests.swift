//
//  CircuitGridTacticsUITests.swift
//  CircuitGridTacticsUITests
//
//  Created by Gopal Kumar on 27/09/26.
//

import XCTest

final class CircuitGridTacticsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Confirm primary window launched
        XCTAssertTrue(app.windows.element(boundBy: 0).exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
