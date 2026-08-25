import AppKit

enum HotkeyTransition {
    static func shouldFire(previousMatch: Bool, currentMatch: Bool, triggerOnKeyUp: Bool) -> Bool {
        triggerOnKeyUp
            ? (!currentMatch && previousMatch)
            : (currentMatch && !previousMatch)
    }
}
