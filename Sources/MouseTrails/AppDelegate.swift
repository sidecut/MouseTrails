import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let overlayController = CircleOverlayController()
    private var globalMonitor: Any?
    private var wasControlPressed = false
    private var toggleMenuItem: NSMenuItem?
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        requestAccessibilityPermissionIfNeeded()
        startGlobalKeyMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        updateStatusIcon()

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.state = isEnabled ? .on : .off
        menu.addItem(toggleItem)
        toggleMenuItem = toggleItem

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About MouseTrails", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
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
            let config = NSImage.SymbolConfiguration(paletteColors: [.systemOrange])
            button.image = image?.withSymbolConfiguration(config)
        } else {
            image?.isTemplate = true
            button.image = image
        }
    }

    private func requestAccessibilityPermissionIfNeeded() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func startGlobalKeyMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let isControlPressed = event.modifierFlags.contains(.control)
        defer { wasControlPressed = isControlPressed }

        guard isControlPressed, !wasControlPressed, isEnabled else { return }

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

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
