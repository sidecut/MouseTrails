import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let overlayController = CircleOverlayController()
    private let mouseTrailController = MouseTrailController()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var mouseMoveMonitor: Any?
    private var localMouseMoveMonitor: Any?
    private var wasHotkeyMatched = false
    private var toggleMenuItem: NSMenuItem?
    private var launchAtLoginMenuItem: NSMenuItem?
    private var isEnabled = true
    private var hotkeySettings = HotkeyDefaultsStore.load()
    private var overlaySettings = OverlayDefaultsStore.load()
    private var mouseTrailSettings = MouseTrailDefaultsStore.load()
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlayController.settings = overlaySettings
        mouseTrailController.settings = mouseTrailSettings
        mouseTrailController.color = overlaySettings.color
        setupStatusItem()
        requestAccessibilityPermissionIfNeeded()
        startGlobalKeyMonitor()
        if mouseTrailSettings.isEnabled {
            startMouseTrailMonitor()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let mouseMoveMonitor {
            NSEvent.removeMonitor(mouseMoveMonitor)
        }
        if let localMouseMoveMonitor {
            NSEvent.removeMonitor(localMouseMoveMonitor)
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
        if isEnabled {
            button.image = Self.statusIcon(color: overlaySettings.color)
        } else {
            let image = NSImage(systemSymbolName: "circle", accessibilityDescription: "MouseTrails")
            image?.isTemplate = true
            button.image = image
        }
    }

    // The menu bar is translucent and sits over an arbitrary desktop background, so a
    // solid dot in the user's chosen trail color can vanish against it (e.g. a magenta
    // dot on a light blue bar). A dark-then-light double outline guarantees at least one
    // ring contrasts with whatever is behind it.
    private static func statusIcon(color: NSColor) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let dot = NSBezierPath(ovalIn: rect.insetBy(dx: 3.5, dy: 3.5))
            color.setFill()
            dot.fill()

            let innerRing = NSBezierPath(ovalIn: rect.insetBy(dx: 3.25, dy: 3.25))
            innerRing.lineWidth = 1
            NSColor.black.withAlphaComponent(0.5).setStroke()
            innerRing.stroke()

            let outerRing = NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            outerRing.lineWidth = 1
            NSColor.white.withAlphaComponent(0.9).setStroke()
            outerRing.stroke()

            return true
        }
        image.accessibilityDescription = "MouseTrails"
        image.isTemplate = false
        return image
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

    private func startMouseTrailMonitor() {
        guard mouseMoveMonitor == nil else { return }
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) {
            [weak self] _ in
            self?.mouseTrailController.recordSample(at: NSEvent.mouseLocation)
        }
        // As with the hotkey monitor, the global monitor above misses movement while
        // one of our own windows (e.g. Settings) is key, so mirror it locally too.
        localMouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) {
            [weak self] event in
            self?.mouseTrailController.recordSample(at: NSEvent.mouseLocation)
            return event
        }
    }

    private func stopMouseTrailMonitor() {
        if let mouseMoveMonitor {
            NSEvent.removeMonitor(mouseMoveMonitor)
            self.mouseMoveMonitor = nil
        }
        if let localMouseMoveMonitor {
            NSEvent.removeMonitor(localMouseMoveMonitor)
            self.localMouseMoveMonitor = nil
        }
        mouseTrailController.clear()
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        guard hotkeySettings.hasValidModifiers else { return }

        let requiredFlags = hotkeySettings.modifierFlags
        let isMatch = event.modifierFlags.isSuperset(of: requiredFlags)
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

        if isEnabled {
            if mouseTrailSettings.isEnabled {
                startMouseTrailMonitor()
            }
            overlayController.cancel()
        } else {
            overlayController.cancel()
            if mouseTrailSettings.isEnabled {
                stopMouseTrailMonitor()
            }
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
                    self?.mouseTrailController.color = updated.color
                    self?.updateStatusIcon()
                    OverlayDefaultsStore.save(updated)
                },
                mouseTrailSettings: mouseTrailSettings,
                onMouseTrailChange: { [weak self] updated in
                    guard let self else { return }
                    let wasEnabled = self.mouseTrailSettings.isEnabled
                    self.mouseTrailSettings = updated
                    self.mouseTrailController.settings = updated
                    if updated.isEnabled && !wasEnabled {
                        self.startMouseTrailMonitor()
                    } else if !updated.isEnabled && wasEnabled {
                        self.stopMouseTrailMonitor()
                    }
                    MouseTrailDefaultsStore.save(updated)
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

        let creditsText: String
        if hotkeySettings.hasValidModifiers {
            let edge = hotkeySettings.triggerOnKeyUp ? "release" : "press"
            creditsText = "\(hotkeySettings.comboDescription) triggers the flash on key \(edge)."
        } else {
            creditsText = "Hotkey is disabled because no modifiers are selected."
        }

        let credits = NSAttributedString(
            string: creditsText,
            attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
        )
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
