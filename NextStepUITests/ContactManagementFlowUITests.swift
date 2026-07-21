import XCTest

final class ContactManagementFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestResetState"]
        app.launch()
        // The app now launches to the Today tab (Specification 3); these tests exercise the
        // Contacts tab, so switch to it once up front.
        app.tabBars.buttons["Contacts"].tap()
    }

    // MARK: - User Story 1: Capture a new contact

    func test_creatingContactWithNameOnly_appearsInList() {
        app.buttons["contactList.addButton"].tap()

        let nameField = app.textFields["contactForm.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Sarah Chen")

        app.buttons["contactForm.saveButton"].tap()

        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
    }

    func test_creatingContactWithAllFields_savesAllValues() {
        app.buttons["contactList.addButton"].tap()

        let nameField = app.textFields["contactForm.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Michael Osei")

        let companyField = app.textFields["contactForm.companyField"]
        companyField.tap()
        companyField.typeText("UBS")

        app.buttons["contactForm.saveButton"].tap()

        XCTAssertTrue(app.staticTexts["Michael Osei"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["UBS"].exists)
    }

    func test_savingWithoutName_showsRequiredErrorAndBlocksSave() {
        app.buttons["contactList.addButton"].tap()

        app.buttons["contactForm.saveButton"].tap()

        XCTAssertTrue(app.staticTexts["contactForm.nameRequiredError"].waitForExistence(timeout: 2))
        // Still on the form, not returned to the list.
        XCTAssertTrue(app.textFields["contactForm.nameField"].exists)
    }

    func test_cancelingContactCreation_doesNotCreateContact() {
        app.buttons["contactList.addButton"].tap()

        let nameField = app.textFields["contactForm.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Discarded Contact")

        app.buttons["contactForm.cancelButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["contactList.emptyState"].waitForExistence(timeout: 2))
    }

    func test_launchingWithNoContacts_showsEmptyStateGuidance() {
        XCTAssertTrue(app.descendants(matching: .any)["contactList.emptyState"].waitForExistence(timeout: 2))
    }

    // MARK: - User Story 2: Find a contact again quickly

    private func createContact(name: String, company: String? = nil, category: String? = nil) {
        app.buttons["contactList.addButton"].tap()

        let nameField = app.textFields["contactForm.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText(name)

        if let company {
            let companyField = app.textFields["contactForm.companyField"]
            companyField.tap()
            companyField.typeText(company)
        }

        if let category {
            app.buttons["contactForm.categoryPicker"].tap()
            app.buttons[category].tap()
        }

        app.buttons["contactForm.saveButton"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 2))
    }

    private func selectCategoryFilter(_ category: String) {
        // The filter menu collapses into the nav bar's "More" overflow button. Inside that
        // overflow presentation its custom accessibilityIdentifier doesn't survive, so it's only
        // reachable by its current label — "Filter" before any category is selected.
        app.buttons["OverflowBarButtonItem"].tap()
        app.buttons["Filter"].tap()
        app.buttons[category].tap()
    }

    func test_searchingByName_showsOnlyMatchingContact() {
        createContact(name: "Sarah Chen")
        createContact(name: "Michael Osei")

        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Sarah")

        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Michael Osei"].exists)
    }

    func test_searchingByCompany_showsOnlyMatchingContact() {
        createContact(name: "Sarah Chen", company: "UBS")
        createContact(name: "Michael Osei", company: "Google")

        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("UBS")

        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Michael Osei"].exists)
    }

    func test_filteringByCategory_showsOnlyMatchingContact() {
        createContact(name: "Sarah Chen", category: "Recruiter")
        createContact(name: "Michael Osei", category: "Peer")

        selectCategoryFilter("Recruiter")

        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Michael Osei"].exists)
    }

    func test_combiningSearchAndCategoryFilter_narrowsToMatchingContact() {
        createContact(name: "Sarah Chen", company: "UBS", category: "Recruiter")
        createContact(name: "Sarah Kim", company: "UBS", category: "Peer")
        createContact(name: "Michael Osei", company: "UBS", category: "Recruiter")

        // Select the category filter before activating search: an active search field hides the
        // nav bar's other toolbar buttons, so the filter menu isn't reachable while it's focused.
        selectCategoryFilter("Recruiter")

        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Sarah")

        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Sarah Kim"].exists)
        XCTAssertFalse(app.staticTexts["Michael Osei"].exists)
    }

    func test_searchWithNoMatches_showsNoResultsState() {
        createContact(name: "Sarah Chen")

        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Nonexistent")

        XCTAssertTrue(app.descendants(matching: .any)["contactList.noResultsState"].waitForExistence(timeout: 2))
    }

    func test_clearingSearch_showsFullListAgain() {
        createContact(name: "Sarah Chen")
        createContact(name: "Michael Osei")

        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Sarah")
        XCTAssertFalse(app.staticTexts["Michael Osei"].exists)

        searchField.buttons["Clear text"].tap()

        XCTAssertTrue(app.staticTexts["Sarah Chen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Michael Osei"].exists)
    }

    // MARK: - User Story 3: Review and update a contact over time

    private func clearAndType(_ field: XCUIElement, _ text: String) {
        field.tap()
        if let existing = field.value as? String, !existing.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deleteString)
        }
        field.typeText(text)
    }

    func test_openingContactDetail_showsStoredFields() {
        createContact(name: "Sarah Chen", company: "UBS", category: "Recruiter")

        app.staticTexts["Sarah Chen"].tap()

        XCTAssertTrue(app.staticTexts["contactDetail.name"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["contactDetail.name"].label.contains("Sarah Chen"))
        XCTAssertTrue(app.staticTexts["contactDetail.company"].label.contains("UBS"))
    }

    func test_editingContact_updatesDetailAndList() {
        createContact(name: "Michael Osei", company: "UBS")

        app.staticTexts["Michael Osei"].tap()
        XCTAssertTrue(app.buttons["contactDetail.editButton"].waitForExistence(timeout: 2))
        app.buttons["contactDetail.editButton"].tap()

        let companyField = app.textFields["contactForm.companyField"]
        XCTAssertTrue(companyField.waitForExistence(timeout: 2))
        clearAndType(companyField, "Google")

        app.buttons["contactForm.saveButton"].tap()

        XCTAssertTrue(app.staticTexts["contactDetail.company"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["contactDetail.company"].label.contains("Google"))

        app.buttons["BackButton"].tap()
        XCTAssertTrue(app.staticTexts["Google"].waitForExistence(timeout: 2))
    }

    func test_cancelingEdit_leavesContactUnchanged() {
        createContact(name: "Sarah Chen", company: "UBS")

        app.staticTexts["Sarah Chen"].tap()
        app.buttons["contactDetail.editButton"].tap()

        let companyField = app.textFields["contactForm.companyField"]
        XCTAssertTrue(companyField.waitForExistence(timeout: 2))
        clearAndType(companyField, "Discarded Company")

        app.buttons["contactForm.cancelButton"].tap()

        XCTAssertTrue(app.staticTexts["contactDetail.company"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["contactDetail.company"].label.contains("UBS"))
    }

    func test_deletingContact_withConfirmation_removesFromList() {
        createContact(name: "Sarah Chen")

        app.staticTexts["Sarah Chen"].tap()
        XCTAssertTrue(app.buttons["contactDetail.deleteButton"].waitForExistence(timeout: 2))
        app.buttons["contactDetail.deleteButton"].tap()

        XCTAssertTrue(app.buttons["contactDetail.confirmDeleteButton"].waitForExistence(timeout: 2))
        app.buttons["contactDetail.confirmDeleteButton"].firstMatch.tap()

        XCTAssertTrue(app.descendants(matching: .any)["contactList.emptyState"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Sarah Chen"].exists)
    }

    func test_relaunchingApp_persistsContactAcrossLaunch() {
        // This test specifically verifies persistence across a process relaunch, which an
        // in-memory store can't demonstrate — it uses the real on-disk store (no
        // -UITestResetState) and cleans up after itself so repeated runs don't accumulate data.
        app.terminate()
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Contacts"].tap()

        let contactName = "Relaunch Persistence Test Contact"

        // Self-heal: remove any leftover contact from a previously interrupted run of this
        // specific test, since it's the one test that touches the real on-disk store.
        while app.staticTexts[contactName].firstMatch.exists {
            app.staticTexts[contactName].firstMatch.tap()
            app.buttons["contactDetail.deleteButton"].tap()
            app.buttons["contactDetail.confirmDeleteButton"].firstMatch.tap()
        }

        app.buttons["contactList.addButton"].tap()
        let nameField = app.textFields["contactForm.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText(contactName)
        app.buttons["contactForm.saveButton"].tap()
        XCTAssertTrue(app.staticTexts[contactName].waitForExistence(timeout: 2))

        app.terminate()
        app.launch()
        app.tabBars.buttons["Contacts"].tap()

        XCTAssertTrue(app.staticTexts[contactName].waitForExistence(timeout: 2))

        app.staticTexts[contactName].firstMatch.tap()
        app.buttons["contactDetail.deleteButton"].tap()
        app.buttons["contactDetail.confirmDeleteButton"].firstMatch.tap()
    }
}
