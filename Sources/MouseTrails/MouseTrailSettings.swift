import Foundation

struct MouseTrailSettings: Equatable {
    var isEnabled: Bool
    var trailLength: Int
    var matchesSystemCursor: Bool

    static let `default` = MouseTrailSettings(
        isEnabled: false, trailLength: 8, matchesSystemCursor: true)
}

enum MouseTrailDefaultsStore {
    private static let isEnabledKey = "mouseTrailIsEnabled"
    private static let trailLengthKey = "mouseTrailLength"
    private static let matchesSystemCursorKey = "mouseTrailMatchesSystemCursor"

    static func load() -> MouseTrailSettings {
        let defaults = UserDefaults.standard
        var settings = MouseTrailSettings.default

        if defaults.object(forKey: isEnabledKey) != nil {
            settings.isEnabled = defaults.bool(forKey: isEnabledKey)
        }
        if defaults.object(forKey: trailLengthKey) != nil {
            settings.trailLength = defaults.integer(forKey: trailLengthKey)
        }
        if defaults.object(forKey: matchesSystemCursorKey) != nil {
            settings.matchesSystemCursor = defaults.bool(forKey: matchesSystemCursorKey)
        }
        return settings
    }

    static func save(_ settings: MouseTrailSettings) {
        let defaults = UserDefaults.standard
        defaults.set(settings.isEnabled, forKey: isEnabledKey)
        defaults.set(settings.trailLength, forKey: trailLengthKey)
        defaults.set(settings.matchesSystemCursor, forKey: matchesSystemCursorKey)
    }
}
