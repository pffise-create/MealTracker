import XCTest

final class AdventureUITests: XCTestCase {
    func testAdventureWorldCompanyAndRecordsRemainNavigable() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        app.tabBars.buttons["Adventure"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["adventure.encounter"].waitForExistence(timeout: 3))
        attachScreenshot(named: "Adventure World")

        app.buttons["Company"].tap()
        XCTAssertTrue(app.staticTexts["The company"].waitForExistence(timeout: 2))
        attachScreenshot(named: "Adventure Company")

        app.buttons["Records"].tap()
        XCTAssertTrue(app.staticTexts["Expedition record"].waitForExistence(timeout: 2))
        attachScreenshot(named: "Adventure Records")
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
