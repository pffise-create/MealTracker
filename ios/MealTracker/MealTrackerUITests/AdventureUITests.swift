import XCTest

final class AdventureUITests: XCTestCase {
    func testCommonwealthIntroductionWaterAndCitizenConsequences() {
        let app = launch()
        XCTAssertTrue(app.buttons["commonwealth.begin"].waitForExistence(timeout: 4))
        attachScreenshot(named: "Briar Glen introduction")
        reveal(app.buttons["commonwealth.begin"], in: app)
        attachScreenshot(named: "Briar Glen inheritance action")
        app.buttons["commonwealth.begin"].tap()
        reveal(app.buttons["commonwealth.action.restoreWater"], in: app)
        XCTAssertTrue(app.buttons["commonwealth.action.restoreWater"].isEnabled)
        app.buttons["commonwealth.action.restoreWater"].tap()
        XCTAssertTrue(app.staticTexts["Water returns"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any)["adventure.balance"].label, "21 experience points banked")
        attachScreenshot(named: "Briar Glen creek action result")
        top(app)
        reveal(app.buttons["commonwealth.site.homestead"], in: app)
        attachScreenshot(named: "Briar Glen living map")
        top(app)
        app.buttons["People"].tap()
        XCTAssertTrue(app.staticTexts["The people behind the fences"].waitForExistence(timeout: 2))
        reveal(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Mara Vale")).firstMatch, in: app)
        attachScreenshot(named: "Briar Glen citizens")
        top(app)
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["Water returns"].waitForExistence(timeout: 2))
        attachScreenshot(named: "Briar Glen journal")
    }

    func testCommonwealthBattleUsesBankOnlyAtStart() {
        let app = launch()
        reveal(app.buttons["commonwealth.begin"], in: app)
        app.buttons["commonwealth.begin"].tap()
        reveal(app.buttons["commonwealth.action.restoreWater"], in: app)
        app.buttons["commonwealth.action.restoreWater"].tap()
        top(app)
        reveal(app.buttons["commonwealth.site.crossing"], in: app)
        app.buttons["commonwealth.site.crossing"].tap()
        reveal(app.buttons["commonwealth.action.patrol"], in: app)
        app.buttons["commonwealth.action.patrol"].tap()
        top(app)
        XCTAssertTrue(app.staticTexts["Hold the crossing"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any)["adventure.balance"].label, "15 experience points banked")
        attachScreenshot(named: "Briar Glen tactical fight")
        reveal(app.buttons["commonwealth.tactic.guard"], in: app)
        attachScreenshot(named: "Briar Glen tactics")
        app.buttons["commonwealth.tactic.guard"].tap()
        XCTAssertTrue(app.staticTexts["You deal 0 damage and take 0."].waitForExistence(timeout: 2))
        top(app)
        XCTAssertEqual(app.descendants(matching: .any)["adventure.balance"].label, "15 experience points banked")
        reveal(app.buttons["commonwealth.tactic.retreat"], in: app)
        app.buttons["commonwealth.tactic.retreat"].tap()
        reveal(app.staticTexts["A safe retreat"], in: app)
        XCTAssertTrue(app.staticTexts["A safe retreat"].exists)
    }

    func testCommonwealthNoXPStillAllowsInspectionAndMealReturn() {
        let app = launch(seedMeals: false)
        reveal(app.buttons["commonwealth.begin"], in: app)
        app.buttons["commonwealth.begin"].tap()
        reveal(app.buttons["commonwealth.action.restoreWater"], in: app)
        XCTAssertFalse(app.buttons["commonwealth.action.restoreWater"].isEnabled)
        let earn = app.buttons["commonwealth.earnXP"].firstMatch
        reveal(earn, in: app)
        earn.tap()
        XCTAssertTrue(app.descendants(matching: .any)["today.completeness"].waitForExistence(timeout: 3))
    }

    private func launch(seedMeals: Bool = true) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"] + (seedMeals ? ["-uiTestingCommonwealth"] : [])
        app.launch()
        app.tabBars.buttons["Adventure"].tap()
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            if element.exists && element.frame.midY < app.frame.midY {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
        }
        attachScreenshot(named: "Unreachable game action")
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    private func top(_ app: XCUIApplication) {
        for _ in 0..<3 { app.swipeDown() }
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
