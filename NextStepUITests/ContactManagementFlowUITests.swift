import XCTest

final class ContactManagementFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITestResetState"]
        app.launch()
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

        XCTAssertTrue(app.otherElements["contactList.emptyState"].waitForExistence(timeout: 2))
    }

    func test_launchingWithNoContacts_showsEmptyStateGuidance() {
        XCTAssertTrue(app.otherElements["contactList.emptyState"].waitForExistence(timeout: 2))
    }
}
