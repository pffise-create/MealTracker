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

        XCTAssertTrue(app.descendants(matching: .any)["recent.confirmation"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["today.log"].exists)

        let loggedMeal = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'today.entry.'")
        ).firstMatch
        XCTAssertTrue(loggedMeal.waitForExistence(timeout: 3))
        XCTAssertTrue(loggedMeal.isHittable)
        attachScreenshot(named: "Today dashboard meal log")
        loggedMeal.tap()
        XCTAssertTrue(app.descendants(matching: .any)["loggedMeal.detail"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["loggedMeal.total"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["loggedMeal.ingredients"].exists)
        XCTAssertGreaterThan(
            app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier BEGINSWITH 'loggedMeal.ingredient.'")
            ).count,
            0
        )
        attachScreenshot(named: "Logged meal ingredient breakdown")
        app.buttons["Done"].tap()

        XCTAssertTrue(app.buttons["recent.edit"].isHittable)
        app.buttons["recent.edit"].tap()
        XCTAssertTrue(app.buttons["entry.save"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
        app.buttons["recent.undo"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["recent.confirmation"].waitForExistence(timeout: 1))
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
        XCTAssertTrue(app.descendants(matching: .any)["today.completeness"].exists)
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["history.calendar"].waitForExistence(timeout: 2))
        app.tabBars.buttons["Adventure"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["adventure.balance"].waitForExistence(timeout: 2))
    }

    func testLiveAIProducesDistinctNutrition() throws {
        guard ProcessInfo.processInfo.environment["MEALTRACKER_LIVE_AI_TEST"] == "1" else {
            throw XCTSkip("Set MEALTRACKER_LIVE_AI_TEST=1 to exercise the configured live backend.")
        }

        app.terminate()
        app.launchArguments = []
        XCUIDevice.shared.orientation = .portrait
        app.launch()

        let beer = try analyzeLiveMeal("one 12 ounce IPA beer")
        let banana = try analyzeLiveMeal("one medium banana")
        let salmonDinner = try analyzeLiveMeal("6 ounces grilled salmon, one cup cooked white rice, and one cup steamed broccoli")

        XCTAssertEqual(beer.ingredientCount, 1, "A beer-only description must not invent dinner foods")
        XCTAssertTrue(80...350 ~= beer.calories, "A 12-ounce IPA should be approximately 80–350 calories")
        XCTAssertTrue(0...5 ~= beer.protein, "A beer should contain little protein")
        XCTAssertTrue(70...150 ~= banana.calories, "A medium banana should be approximately 70–150 calories")
        XCTAssertTrue(0...3 ~= banana.protein, "A medium banana should contain little protein")
        XCTAssertTrue(500...950 ~= salmonDinner.calories, "The specified salmon dinner should be approximately 500–950 calories")
        XCTAssertTrue(35...80 ~= salmonDinner.protein, "Six ounces of salmon should make this a high-protein dinner")
        XCTAssertLessThan(banana.calories, salmonDinner.calories)
        XCTAssertLessThan(banana.protein, salmonDinner.protein)
        XCTAssertGreaterThan(salmonDinner.calories - banana.calories, 250)
        XCTAssertGreaterThan(salmonDinner.protein - banana.protein, 20)
    }

    func testLiveRestaurantFindsOfficialStoneWayMenu() throws {
        guard ProcessInfo.processInfo.environment["MEALTRACKER_LIVE_MENU_TEST"] == "1" else {
            throw XCTSkip("Set MEALTRACKER_LIVE_MENU_TEST=1 to exercise live official-menu search.")
        }

        app.terminate()
        app.launchArguments = ["-uiTestingRestaurantStoneWay"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()

        let restaurant = app.buttons["today.restaurant"]
        XCTAssertTrue(restaurant.waitForExistence(timeout: 8))
        restaurant.tap()

        let venue = app.buttons["restaurant.venue.stone-way-cafe-seattle"]
        XCTAssertTrue(venue.waitForExistence(timeout: 4))
        venue.tap()
        app.buttons["restaurant.fullMenu"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["restaurant.menuSource"].waitForExistence(timeout: 90),
            "The official Stone Way Cafe menu was not found"
        )
        XCTAssertTrue(app.staticTexts["Breakfast Sandwich"].exists)
        XCTAssertTrue(app.staticTexts["Waffles"].exists)
        attachScreenshot(named: "Stone Way Cafe official menu results")
    }

    private func analyzeLiveMeal(_ description: String) throws -> (calories: Double, protein: Double, ingredientCount: Int) {
        XCUIDevice.shared.orientation = .portrait
        let capture = app.buttons["today.capture"]
        XCTAssertTrue(capture.waitForExistence(timeout: 8))
        capture.tap()

        let typeIt = app.buttons["capture.Type-it"]
        XCTAssertTrue(typeIt.waitForExistence(timeout: 3))
        typeIt.tap()

        let text = app.textFields["capture.text"]
        XCTAssertTrue(text.waitForExistence(timeout: 3))
        text.tap()
        text.typeText(description)
        app.buttons["capture.logText"].tap()

        let confirmation = app.descendants(matching: .any)["recent.confirmation"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 90), "Live meal analysis did not finish")
        defer {
            if app.navigationBars["Edit log"].exists { app.buttons["Cancel"].tap() }
            if app.buttons["recent.undo"].waitForExistence(timeout: 3) { app.buttons["recent.undo"].tap() }
        }
        XCUIDevice.shared.orientation = .portrait
        app.buttons["recent.edit"].tap()

        let caloriesField = app.textFields["entry.nutrition.calories"]
        let proteinField = app.textFields["entry.nutrition.protein"]
        XCTAssertTrue(caloriesField.waitForExistence(timeout: 4))
        guard let calories = Double(caloriesField.value as? String ?? ""),
              let protein = Double(proteinField.value as? String ?? "") else {
            XCTFail("The AI result did not contain numeric nutrition")
            throw NSError(domain: "MealTrackerLiveAITest", code: 1)
        }
        let ingredientCount = app.textFields.matching(
            NSPredicate(format: "identifier BEGINSWITH 'entry.ingredient.'")
        ).count

        return (calories, protein, ingredientCount)
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
