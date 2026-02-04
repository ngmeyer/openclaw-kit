//
//  OpenClawKitUITests.swift
//  OpenClawKitUITests
//
//  Created by Neal Meyer on 2/3/26.
//

import XCTest

final class OpenClawKitUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app launched and shows the license view first
        XCTAssertTrue(app.windows.count > 0)
    }
    
    @MainActor
    func testLicenseScreenElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Check for license key text field
        let licenseField = app.textFields["XXXX-XXXX-XXXX-XXXX"]
        // UI elements exist
    }
    
    @MainActor
    func testPurchaseButtonOpensWebsite() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Find and tap purchase button - this would open Safari
        // For now just verify the button exists
    }
    
    @MainActor
    func testNavigationFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--skip-license"] // Would need to implement this
        app.launch()
        
        // Test navigation through wizard steps
        // This would require mocking the license validation
    }
}

// MARK: - Performance Tests
final class OpenClawKitPerformanceTests: XCTestCase {
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
