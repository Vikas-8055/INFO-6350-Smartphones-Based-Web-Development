import XCTest

final class TravelPlannerAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Optional: Clean up after each test
    }

    // MARK: - Basic App Launch Test

    @MainActor
    func testAppLaunchesAndShowsTabs() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify tab bar items exist
        let destinationsTab = app.tabBars.buttons["Destinations"]
        let tripsTab = app.tabBars.buttons["Trips"]

        XCTAssertTrue(destinationsTab.exists, "Destinations tab should be present")
        XCTAssertTrue(tripsTab.exists, "Trips tab should be present")

        // Tap Destinations and look for Add (+) button
        destinationsTab.tap()
        XCTAssertTrue(app.buttons["plus"].exists, "Add Destination (+) button should be visible")

        // Tap Trips and look for Add (+) button
        tripsTab.tap()
        XCTAssertTrue(app.buttons["plus"].exists, "Add Trip (+) button should be visible")
    }

    // MARK: - Launch Performance Test

    @MainActor
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
