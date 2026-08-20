import AppKit

struct OverlaySettings: Equatable {
    var color: NSColor
    var lineWidth: CGFloat
    var repeatCount: Int

    static let `default` = OverlaySettings(
        color: .systemOrange,
        lineWidth: 3,
        repeatCount: 1
    )
}

enum OverlayDefaultsStore {
    private static let colorKey = "overlayColor"
    private static let lineWidthKey = "overlayLineWidth"
    private static let repeatCountKey = "overlayRepeatCount"

    static func load() -> OverlaySettings {
        let defaults = UserDefaults.standard
        var settings = OverlaySettings.default

        if let data = defaults.data(forKey: colorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
            settings.color = color
        }
        if defaults.object(forKey: lineWidthKey) != nil {
            settings.lineWidth = CGFloat(defaults.double(forKey: lineWidthKey))
        }
        if defaults.object(forKey: repeatCountKey) != nil {
            settings.repeatCount = defaults.integer(forKey: repeatCountKey)
        }
        return settings
    }

    static func save(_ settings: OverlaySettings) {
        let defaults = UserDefaults.standard
        if let data = try? NSKeyedArchiver.archivedData(
            withRootObject: settings.color, requiringSecureCoding: false
        ) {
            defaults.set(data, forKey: colorKey)
        }
        defaults.set(Double(settings.lineWidth), forKey: lineWidthKey)
        defaults.set(settings.repeatCount, forKey: repeatCountKey)
    }
}
