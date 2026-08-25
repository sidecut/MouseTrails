import XCTest

@testable import MouseTrails

final class HotkeySettingsTests: XCTestCase {
    func testHotkeyStateResetsWhenModifiersAreCleared() {
        var settings = HotkeySettings.default
        settings.modifierOptions = [.control]

        XCTAssertTrue(settings.hasValidModifiers)

        settings.modifierOptions = []
        XCTAssertFalse(settings.hasValidModifiers)
    }

    func testHotkeyTransitionIgnoresStalePreviousState() {
        XCTAssertTrue(
            HotkeyTransition.shouldFire(
                previousMatch: false,
                currentMatch: true,
                triggerOnKeyUp: false
            )
        )

        XCTAssertTrue(
            HotkeyTransition.shouldFire(
                previousMatch: true,
                currentMatch: false,
                triggerOnKeyUp: true
            )
        )

        XCTAssertFalse(
            HotkeyTransition.shouldFire(
                previousMatch: false,
                currentMatch: false,
                triggerOnKeyUp: false
            )
        )
    }

    func testHotkeyStateMatchesExpectedComboDescription() {
        let settings = HotkeySettings(
            modifierOptions: [.command, .option],
            triggerOnKeyUp: false
        )

        XCTAssertEqual(settings.comboDescription, "Option+Cmd")
        XCTAssertEqual(settings.modifierFlags, [.option, .command])
    }
}
