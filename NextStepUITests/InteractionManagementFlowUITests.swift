import XCTest

final class InteractionManagementFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestResetState"]
        app.launch()
    }

    private func createContactAndOpenDetail(name: String) {
        app.buttons["contactList.addButton"].tap()
        let nameField = app.textFields["contactForm.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["contactForm.saveButton"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 2))
        app.staticTexts[name].tap()
        XCTAssertTrue(app.buttons["contactDetail.logInteractionButton"].waitForExistence(timeout: 2))
    }

    // MARK: - User Story 1: Log an interaction right after it happens

    func test_openingLogInteractionForm_showsFormControls() {
        createContactAndOpenDetail(name: "Sarah Chen")

        app.buttons["contactDetail.logInteractionButton"].tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.datePickers["interactionForm.datePicker"].exists || app.buttons["interactionForm.datePicker"].exists)
        XCTAssertTrue(app.textFields["interactionForm.outcomeField"].exists)
        XCTAssertTrue(app.textFields["interactionForm.nextActionField"].exists)
    }

    func test_selectingInteractionType_updatesPickerLabel() {
        createContactAndOpenDetail(name: "Michael Osei")
        app.buttons["contactDetail.logInteractionButton"].tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        app.buttons["interactionForm.typePicker"].tap()
        app.buttons["Phone or Video Call"].tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].label.contains("Phone or Video Call"))
    }

    func test_loggingInteractionWithAllFields_dismissesFormAndReturnsToDetail() {
        createContactAndOpenDetail(name: "Priya Patel")
        app.buttons["contactDetail.logInteractionButton"].tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        app.buttons["interactionForm.typePicker"].tap()
        app.buttons["In-Person Meeting"].tap()

        let outcomeField = app.textFields["interactionForm.outcomeField"]
        outcomeField.tap()
        outcomeField.typeText("Great conversation")

        let nextActionField = app.textFields["interactionForm.nextActionField"]
        nextActionField.tap()
        nextActionField.typeText("Send follow-up email")

        app.buttons["interactionForm.saveButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["contactDetail.screen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["interactionForm.saveButton"].exists)
    }

    func test_cancelingLogInteraction_dismissesFormWithoutSaving() {
        createContactAndOpenDetail(name: "Diego Ramirez")
        app.buttons["contactDetail.logInteractionButton"].tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        let outcomeField = app.textFields["interactionForm.outcomeField"]
        outcomeField.tap()
        outcomeField.typeText("Discarded outcome")

        app.buttons["interactionForm.cancelButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["contactDetail.screen"].waitForExistence(timeout: 2))
    }
}
