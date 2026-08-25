import AppKit

enum ModifierOption: String, CaseIterable {
    case control
    case option
    case shift
    case command
    case function

    var flag: NSEvent.ModifierFlags {
        switch self {
        case .control: return .control
        case .option: return .option
        case .shift: return .shift
        case .command: return .command
        case .function: return .function
        }
    }

    var displayName: String {
        switch self {
        case .control: return "Ctrl"
        case .option: return "Option"
        case .shift: return "Shift"
        case .command: return "Cmd"
        case .function: return "Fn"
        }
    }
}

struct HotkeySettings: Equatable {
    var modifierOptions: Set<ModifierOption>
    var triggerOnKeyUp: Bool

    static let `default` = HotkeySettings(
        modifierOptions: [.control, .function], triggerOnKeyUp: false)

    var modifierFlags: NSEvent.ModifierFlags {
        modifierOptions.reduce(into: []) { $0.formUnion($1.flag) }
    }

    var comboDescription: String {
        guard !modifierOptions.isEmpty else { return "No modifiers selected" }
        return ModifierOption.allCases
            .filter { modifierOptions.contains($0) }
            .map(\.displayName)
            .joined(separator: "+")
    }

    var hasValidModifiers: Bool {
        !modifierOptions.isEmpty
    }
}

enum HotkeyDefaultsStore {
    private static let modifiersKey = "hotkeyModifiers"
    private static let triggerOnKeyUpKey = "hotkeyTriggerOnKeyUp"

    static func load() -> HotkeySettings {
        let defaults = UserDefaults.standard
        guard let storedRaw = defaults.array(forKey: modifiersKey) as? [String] else {
            return .default
        }
        let options = Set(storedRaw.compactMap(ModifierOption.init(rawValue:)))
        let triggerOnKeyUp = defaults.bool(forKey: triggerOnKeyUpKey)
        return HotkeySettings(modifierOptions: options, triggerOnKeyUp: triggerOnKeyUp)
    }

    static func save(_ settings: HotkeySettings) {
        let defaults = UserDefaults.standard
        defaults.set(settings.modifierOptions.map(\.rawValue), forKey: modifiersKey)
        defaults.set(settings.triggerOnKeyUp, forKey: triggerOnKeyUpKey)
    }
}
