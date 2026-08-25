import AppKit

let openSettingsOnLaunch = CommandLine.arguments.contains("--config")
let app = NSApplication.shared
let delegate = AppDelegate(openSettingsOnLaunch: openSettingsOnLaunch)
app.delegate = delegate
app.run()
