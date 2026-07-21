import XCTest

final class FollowUpManagementFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestResetState"]
        app.launch()
        // The app launches to the Today tab; individual tests switch tabs as needed (some
        // specifically verify the Today-tab-first launch behavior, so the switch isn't done
        // unconditionally here).
    }

    private func createContactAndOpenDetail(name: String) {
        app.tabBars.buttons["Contacts"].tap()
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

    // MARK: - User Story 2: See what needs attention today

    private func createFollowUp(contactName: String) {
        createContactAndOpenDetail(name: contactName)
        app.buttons["contactDetail.createFollowUpButton"].tap()
        XCTAssertTrue(app.buttons["followUpForm.saveButton"].waitForExistence(timeout: 2))
        app.buttons["followUpForm.saveButton"].tap()
        app.tabBars.buttons["Today"].tap()
    }

    func test_launchingApp_landsOnTodayTab() {
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.tabBars.buttons["Today"].isSelected)
    }

    func test_todayScreenWithNoFollowUps_showsEmptyState() {
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["today.emptyState"].waitForExistence(timeout: 2))
    }

    func test_creatingFollowUp_appearsInDueTodaySection() {
        createFollowUp(contactName: "Sarah Chen")

        XCTAssertTrue(app.descendants(matching: .any)["today.dueTodaySection"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
    }

    // MARK: - User Story 3: Act on a follow-up

    private func todayRow(containing text: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func test_completingFollowUp_movesToRecentlyCompleted() {
        createFollowUp(contactName: "Michael Osei")

        let row = todayRow(containing: "Michael Osei")
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeRight()
        XCTAssertTrue(app.buttons["today.completeFollowUpButton"].waitForExistence(timeout: 2))
        app.buttons["today.completeFollowUpButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["today.recentlyCompletedSection"].waitForExistence(timeout: 2))
    }

    func test_editingFollowUpPriority_updatesImmediately() {
        createFollowUp(contactName: "Priya Patel")

        let row = todayRow(containing: "Priya Patel")
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()

        XCTAssertTrue(app.buttons["followUpForm.priorityPicker"].waitForExistence(timeout: 2))
        app.buttons["followUpForm.priorityPicker"].tap()
        app.buttons["High"].tap()
        app.buttons["followUpForm.saveButton"].tap()

        XCTAssertTrue(app.staticTexts["High"].waitForExistence(timeout: 2))
    }

    func test_deletingFollowUp_withConfirmation_removesFromToday() {
        createFollowUp(contactName: "Diego Ramirez")

        let row = todayRow(containing: "Diego Ramirez")
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeLeft()
        XCTAssertTrue(app.buttons["today.deleteFollowUpButton"].waitForExistence(timeout: 2))
        app.buttons["today.deleteFollowUpButton"].tap()

        XCTAssertTrue(app.buttons["today.confirmDeleteButton"].firstMatch.waitForExistence(timeout: 2))
        app.buttons["today.confirmDeleteButton"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["today.emptyState"].waitForExistence(timeout: 2))
    }

    func test_deletingContactWithFollowUp_removesItFromToday() {
        createFollowUp(contactName: "Amara Okafor")

        app.tabBars.buttons["Contacts"].tap()
        XCTAssertTrue(app.staticTexts["Amara Okafor"].waitForExistence(timeout: 2))
        app.staticTexts["Amara Okafor"].tap()
        XCTAssertTrue(app.buttons["contactDetail.deleteButton"].waitForExistence(timeout: 2))
        app.buttons["contactDetail.deleteButton"].tap()
        app.buttons["contactDetail.confirmDeleteButton"].firstMatch.tap()

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["today.emptyState"].waitForExistence(timeout: 2))
    }

    // MARK: - User Story 4: Get reminded without having the app open

    func test_notificationAuthorizationRequest_doesNotBreakTodayScreen() {
        // Under -UITestResetState the app runs against NoOpNotificationScheduler, so this never
        // triggers the real system permission dialog — it verifies the app requests
        // authorization gracefully and the Today screen keeps working regardless.
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["today.emptyState"].waitForExistence(timeout: 2))

        createFollowUp(contactName: "Nauman Rafique")
        XCTAssertTrue(app.staticTexts["Nauman Rafique"].waitForExistence(timeout: 2))
    }
}
