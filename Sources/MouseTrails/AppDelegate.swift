import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let overlayController = CircleOverlayController()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var wasHotkeyMatched = false
    private var toggleMenuItem: NSMenuItem?
    private var launchAtLoginMenuItem: NSMenuItem?
    private var isEnabled = true
    private var hotkeySettings = HotkeyDefaultsStore.load()
    private var overlaySettings = OverlayDefaultsStore.load()
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlayController.settings = overlaySettings
        setupStatusItem()
        requestAccessibilityPermissionIfNeeded()
        startGlobalKeyMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        updateStatusIcon()

        let menu = NSMenu()
        let toggleItem = NSMenuItem(
            title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.state = isEnabled ? .on : .off
        menu.addItem(toggleItem)
        toggleMenuItem = toggleItem

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)
        launchAtLoginMenuItem = launchAtLoginItem

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Settings…", action: #selector(showHotkeySettings),
                keyEquivalent: ""))

        menu.addItem(
            NSMenuItem(title: "About MouseTrails", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        for menuItem in menu.items {
            menuItem.target = self
        }

        item.menu = menu
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        let image = NSImage(systemSymbolName: "circle", accessibilityDescription: "MouseTrails")
        if isEnabled {
            let config = NSImage.SymbolConfiguration(paletteColors: [overlaySettings.color])
            button.image = image?.withSymbolConfiguration(config)
        } else {
            image?.isTemplate = true
            button.image = image
        }
    }

    private func requestAccessibilityPermissionIfNeeded() {
        let options: [String: Any] = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func startGlobalKeyMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) {
            [weak self] event in
            self?.handleFlagsChanged(event)
        }
        // The global monitor above only sees events destined for other apps, so it misses
        // the hotkey while one of our own windows (e.g. the About panel) is key.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let requiredFlags = hotkeySettings.modifierFlags
        let isMatch = !requiredFlags.isEmpty && event.modifierFlags.isSuperset(of: requiredFlags)
        defer { wasHotkeyMatched = isMatch }

        let shouldFire =
            hotkeySettings.triggerOnKeyUp
            ? (!isMatch && wasHotkeyMatched)
            : (isMatch && !wasHotkeyMatched)

        guard shouldFire, isEnabled else { return }

        overlayController.flash(at: NSEvent.mouseLocation)
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        toggleMenuItem?.state = isEnabled ? .on : .off
        updateStatusIcon()
        if !isEnabled {
            overlayController.cancel()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let shouldEnable = SMAppService.mainApp.status != .enabled
        do {
            if shouldEnable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't update Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        launchAtLoginMenuItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func showHotkeySettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                hotkeySettings: hotkeySettings,
                onHotkeyChange: { [weak self] updated in
                    self?.hotkeySettings = updated
                    HotkeyDefaultsStore.save(updated)
                },
                overlaySettings: overlaySettings,
                onOverlayChange: { [weak self] updated in
                    self?.overlaySettings = updated
                    self?.overlayController.settings = updated
                    self?.updateStatusIcon()
                    OverlayDefaultsStore.save(updated)
                }
            )
        }
        NSApp.activate(ignoringOtherApps: true)
        if let window = settingsWindowController?.window {
            center(window, onScreenContaining: NSEvent.mouseLocation)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func center(_ window: NSWindow, onScreenContaining point: NSPoint) {
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        guard let screen else { return }
        let visibleFrame = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(
            NSPoint(
                x: visibleFrame.midX - size.width / 2,
                y: visibleFrame.midY - size.height / 2
            ))
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let edge = hotkeySettings.triggerOnKeyUp ? "release" : "press"
        let credits = NSAttributedString(
            string: "\(hotkeySettings.comboDescription) triggers the flash on key \(edge).",
            attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
        )
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
