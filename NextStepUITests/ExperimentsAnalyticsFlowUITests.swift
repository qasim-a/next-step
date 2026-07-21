import XCTest

final class ExperimentsAnalyticsFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestResetState"]
        app.launch()
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

    private func createFollowUp(contactName: String) {
        createContactAndOpenDetail(name: contactName)
        app.buttons["contactDetail.createFollowUpButton"].tap()
        XCTAssertTrue(app.buttons["followUpForm.saveButton"].waitForExistence(timeout: 2))
        app.buttons["followUpForm.saveButton"].tap()
        app.tabBars.buttons["Today"].tap()
    }

    private func openSummary() {
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["today.insightsButton"].waitForExistence(timeout: 2))
        app.buttons["today.insightsButton"].tap()
    }

    private func openDeveloperAnalytics() {
        // The overflow-menu button loses its custom identifier once collapsed into the nav bar's
        // "More" popover (only its label survives) — same constraint as the category filter menu
        // in ContactManagementFlowUITests.
        app.tabBars.buttons["Contacts"].tap()
        // The Contacts tab's navigation stack persists across tab switches (TabView keeps every
        // tab alive), so if a contact was pushed earlier in this test, re-selecting the tab
        // returns to that detail screen rather than the list — pop back first if needed.
        if app.navigationBars.buttons["BackButton"].exists {
            app.navigationBars.buttons["BackButton"].tap()
        }
        app.buttons["OverflowBarButtonItem"].tap()
        app.buttons["Developer Info"].tap()
    }

    // MARK: - User Story 1: See how I'm doing on follow-ups

    func test_summaryWithNoFollowUps_showsEmptyState() {
        openSummary()
        XCTAssertTrue(app.staticTexts["followUpSummary.emptyState"].waitForExistence(timeout: 2))
    }

    func test_summaryReflectsCompletedAndOverdueFollowUps() {
        createFollowUp(contactName: "Sarah Chen")

        let row = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Sarah Chen")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeRight()
        XCTAssertTrue(app.buttons["today.completeFollowUpButton"].waitForExistence(timeout: 2))
        app.buttons["today.completeFollowUpButton"].tap()

        app.buttons["today.insightsButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["followUpSummary.list"].waitForExistence(timeout: 2))
        let completedRow = app.descendants(matching: .any)["followUpSummary.completedCount"]
        XCTAssertTrue(completedRow.waitForExistence(timeout: 2))
        XCTAssertTrue(completedRow.label.contains("1"))
    }

    func test_summaryUpdatesImmediatelyAfterCompletingAFollowUp() {
        createFollowUp(contactName: "Michael Osei")
        openSummary()

        let emptyCompletionRate = app.descendants(matching: .any)["followUpSummary.completionRate"]
        XCTAssertTrue(emptyCompletionRate.waitForExistence(timeout: 2))
        app.buttons["followUpSummary.doneButton"].tap()

        let row = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Michael Osei")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeRight()
        XCTAssertTrue(app.buttons["today.completeFollowUpButton"].waitForExistence(timeout: 2))
        app.buttons["today.completeFollowUpButton"].tap()

        app.buttons["today.insightsButton"].tap()
        let completedRow = app.descendants(matching: .any)["followUpSummary.completedCount"]
        XCTAssertTrue(completedRow.waitForExistence(timeout: 2))
        XCTAssertTrue(completedRow.label.contains("1"))
    }

    // MARK: - User Story 3: Inspect what's being tracked

    func test_developerScreenWithNoEventsYet_showsEmptyState() {
        openDeveloperAnalytics()
        XCTAssertTrue(app.staticTexts["developerAnalytics.emptyState"].waitForExistence(timeout: 2))
    }

    func test_developerScreenListsTrackedEvents_mostRecentFirst() {
        // Opening the contact detail fires contactOpened; completing the follow-up afterward
        // fires followUpCompleted, so it should sort above contactOpened (most-recent-first).
        createFollowUp(contactName: "Priya Patel")
        let row = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Priya Patel")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.swipeRight()
        XCTAssertTrue(app.buttons["today.completeFollowUpButton"].waitForExistence(timeout: 2))
        app.buttons["today.completeFollowUpButton"].tap()

        openDeveloperAnalytics()
        let events = app.staticTexts.matching(identifier: "developerAnalytics.event")
        XCTAssertTrue(events.firstMatch.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(events.count, 2)
        XCTAssertTrue(events.element(boundBy: 0).label.contains("Follow-Up Completed"))
    }

    func test_developerScreenShowsAssignedExperimentVariant() {
        openDeveloperAnalytics()
        XCTAssertTrue(app.staticTexts["developerAnalytics.emptyState"].waitForExistence(timeout: 2))
        let variantRow = app.descendants(matching: .any)["developerAnalytics.variant"]
        XCTAssertTrue(variantRow.waitForExistence(timeout: 2))
        XCTAssertTrue(variantRow.label.contains("Control") || variantRow.label.contains("Variant"))
    }
}
