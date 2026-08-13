import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let overlayController = CircleOverlayController()
    private var globalMonitor: Any?
    private var wasControlPressed = false

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
        if let button = item.button {
            let image = NSImage(systemSymbolName: "circle", accessibilityDescription: "MouseTrails")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About MouseTrails", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        for menuItem in menu.items {
            menuItem.target = self
        }

        item.menu = menu
        statusItem = item
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

        guard isControlPressed, !wasControlPressed else { return }

        overlayController.flash(at: NSEvent.mouseLocation)
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
