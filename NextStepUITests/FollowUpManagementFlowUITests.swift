import XCTest

final class FollowUpManagementFlowUITests: XCTestCase {
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
        XCTAssertTrue(app.buttons["contactDetail.createFollowUpButton"].waitForExistence(timeout: 2))
    }

    // MARK: - User Story 1: Capture a follow-up for a contact

    func test_openingCreateFollowUpForm_showsFormControls() {
        createContactAndOpenDetail(name: "Sarah Chen")

        app.buttons["contactDetail.createFollowUpButton"].tap()

        XCTAssertTrue(app.datePickers["followUpForm.dueDatePicker"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["followUpForm.priorityPicker"].exists)
        XCTAssertTrue(app.textViews["followUpForm.suggestedActionField"].exists)
    }

    func test_selectingPriority_updatesPickerLabel() {
        createContactAndOpenDetail(name: "Michael Osei")
        app.buttons["contactDetail.createFollowUpButton"].tap()

        XCTAssertTrue(app.buttons["followUpForm.priorityPicker"].waitForExistence(timeout: 2))
        app.buttons["followUpForm.priorityPicker"].tap()
        app.buttons["High"].tap()

        XCTAssertTrue(app.buttons["followUpForm.priorityPicker"].label.contains("High"))
    }

    func test_creatingFollowUpWithDueDateOnly_dismissesFormAndReturnsToDetail() {
        createContactAndOpenDetail(name: "Priya Patel")
        app.buttons["contactDetail.createFollowUpButton"].tap()

        XCTAssertTrue(app.buttons["followUpForm.saveButton"].waitForExistence(timeout: 2))
        app.buttons["followUpForm.saveButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["contactDetail.screen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["followUpForm.saveButton"].exists)
    }

    func test_cancelingCreateFollowUp_dismissesFormWithoutSaving() {
        createContactAndOpenDetail(name: "Diego Ramirez")
        app.buttons["contactDetail.createFollowUpButton"].tap()

        XCTAssertTrue(app.buttons["followUpForm.cancelButton"].waitForExistence(timeout: 2))
        let suggestedActionField = app.textViews["followUpForm.suggestedActionField"]
        suggestedActionField.tap()
        suggestedActionField.typeText("Discarded suggested action")

        app.buttons["followUpForm.cancelButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["contactDetail.screen"].waitForExistence(timeout: 2))
    }

    func test_creatingFollowUpFromInteraction_prefillsSuggestedAction() {
        createContactAndOpenDetail(name: "Amara Okafor")

        // Log an interaction with next-action text to create a follow-up from.
        app.buttons["contactDetail.logInteractionButton"].tap()
        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        let nextActionField = app.textFields["interactionForm.nextActionField"]
        nextActionField.tap()
        nextActionField.typeText("Send the case study")
        app.buttons["interactionForm.saveButton"].tap()

        let row = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Email")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeRight()

        XCTAssertTrue(app.buttons["contactDetail.createFollowUpFromInteractionButton"].waitForExistence(timeout: 2))
        app.buttons["contactDetail.createFollowUpFromInteractionButton"].tap()

        let suggestedActionField = app.textViews["followUpForm.suggestedActionField"]
        XCTAssertTrue(suggestedActionField.waitForExistence(timeout: 2))
        XCTAssertEqual(suggestedActionField.value as? String, "Send the case study")
    }
}
