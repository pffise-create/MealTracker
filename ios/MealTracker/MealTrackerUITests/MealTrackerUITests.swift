import XCTest

final class MealTrackerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    func testLogPredictedMealEditPortionAndUndo() {
        let prediction = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'prediction.'")
        ).firstMatch
        XCTAssertTrue(prediction.waitForExistence(timeout: 5))
        prediction.tap()

        app.buttons["meal.portion"].tap()
        XCTAssertTrue(app.buttons["portion.generous"].waitForExistence(timeout: 2))
        app.buttons["portion.generous"].tap()

        let ingredient = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'ingredient.toggle.'")
        ).firstMatch
        XCTAssertTrue(ingredient.exists)
        ingredient.tap()
        app.buttons["meal.log"].tap()

        XCTAssertTrue(app.otherElements["recent.confirmation"].waitForExistence(timeout: 3))
        app.buttons["recent.edit"].tap()
        XCTAssertTrue(app.buttons["entry.save"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
        app.buttons["recent.undo"].tap()
        XCTAssertFalse(app.otherElements["recent.confirmation"].waitForExistence(timeout: 1))
    }

    func testMarkCategorySkippedAndCompleteDay() {
        app.buttons["today.skipMenu"].tap()
        app.buttons["No Breakfast"].tap()
        app.buttons["today.endDay"].tap()
        XCTAssertTrue(app.buttons["endDay.finish"].waitForExistence(timeout: 2))
        app.buttons["endDay.finish"].tap()
        XCTAssertTrue(app.staticTexts["Today is fully resolved"].waitForExistence(timeout: 3))
    }

    func testRecoverIncompleteHistoricalDay() {
        app.terminate()
        app.launchArguments = ["-uiTesting", "-uiTestingRecovery"]
        app.launch()
        app.tabBars.buttons["History"].tap()

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let identifier = formatter.string(from: yesterday)
        let dayButton = app.buttons["history.day.\(identifier)"]
        XCTAssertTrue(dayButton.waitForExistence(timeout: 4))
        dayButton.tap()

        for category in ["lunch", "dinner", "snacks"] {
            let button = app.buttons["history.skip.\(category)"]
            XCTAssertTrue(button.waitForExistence(timeout: 2))
            button.tap()
        }
        XCTAssertTrue(app.staticTexts["Day complete"].waitForExistence(timeout: 3))
    }

    func testNavigatePrimaryDestinations() {
        XCTAssertTrue(app.otherElements["today.completeness"].exists)
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.otherElements["history.calendar"].waitForExistence(timeout: 2))
        app.tabBars.buttons["Adventure"].tap()
        XCTAssertTrue(app.otherElements["adventure.balance"].waitForExistence(timeout: 2))
    }
}
