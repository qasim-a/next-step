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

    // MARK: - User Story 2: See a contact's interaction history at a glance

    private func logInteraction(type: String? = nil) {
        app.buttons["contactDetail.logInteractionButton"].tap()
        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        if let type {
            app.buttons["interactionForm.typePicker"].tap()
            app.buttons[type].tap()
        }
        app.buttons["interactionForm.saveButton"].tap()
    }

    func test_contactWithNoInteractions_showsTimelineEmptyState() {
        createContactAndOpenDetail(name: "Sarah Chen")

        XCTAssertTrue(app.staticTexts["contactDetail.timelineEmptyState"].waitForExistence(timeout: 2))
    }

    func test_loggingTwoInteractions_showsMostRecentlyLoggedFirst() {
        createContactAndOpenDetail(name: "Michael Osei")

        logInteraction(type: "Email")
        XCTAssertTrue(app.staticTexts["Email, \(todayFormatted())"].waitForExistence(timeout: 2))

        logInteraction(type: "Phone or Video Call")
        let phoneRow = app.staticTexts["Phone or Video Call, \(todayFormatted())"]
        let emailRow = app.staticTexts["Email, \(todayFormatted())"]
        XCTAssertTrue(phoneRow.waitForExistence(timeout: 2))
        XCTAssertTrue(emailRow.exists)

        // Same date, so the more-recently-logged (Phone) interaction should sort above Email.
        XCTAssertLessThan(phoneRow.frame.minY, emailRow.frame.minY)
    }

    private func todayFormatted() -> String {
        Date.now.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - User Story 3: Correct or remove a logged interaction

    private func timelineRow(containing text: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func test_editingInteraction_updatesTimeline() {
        createContactAndOpenDetail(name: "Sarah Chen")
        logInteraction(type: "Email")

        let row = timelineRow(containing: "Email")
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        app.buttons["interactionForm.typePicker"].tap()
        app.buttons["Interview"].tap()
        app.buttons["interactionForm.saveButton"].tap()

        let updatedRow = timelineRow(containing: "Interview")
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 2))
    }

    func test_cancelingInteractionEdit_leavesInteractionUnchanged() {
        createContactAndOpenDetail(name: "Michael Osei")
        logInteraction(type: "Email")

        let row = timelineRow(containing: "Email")
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()

        XCTAssertTrue(app.buttons["interactionForm.typePicker"].waitForExistence(timeout: 2))
        app.buttons["interactionForm.typePicker"].tap()
        app.buttons["Interview"].tap()
        app.buttons["interactionForm.cancelButton"].tap()

        let unchangedRow = timelineRow(containing: "Email")
        XCTAssertTrue(unchangedRow.waitForExistence(timeout: 2))
    }

    func test_deletingInteraction_withConfirmation_removesFromTimeline() {
        createContactAndOpenDetail(name: "Priya Patel")
        logInteraction(type: "Email")

        let row = timelineRow(containing: "Email")
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeLeft()

        XCTAssertTrue(app.buttons["contactDetail.deleteInteractionButton"].waitForExistence(timeout: 2))
        app.buttons["contactDetail.deleteInteractionButton"].tap()

        XCTAssertTrue(app.buttons["contactDetail.confirmDeleteInteractionButton"].firstMatch.waitForExistence(timeout: 2))
        app.buttons["contactDetail.confirmDeleteInteractionButton"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["contactDetail.timelineEmptyState"].waitForExistence(timeout: 2))
    }
}
