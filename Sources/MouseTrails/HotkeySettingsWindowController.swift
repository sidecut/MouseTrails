import AppKit

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private var hotkeySettings: HotkeySettings
    private let onHotkeyChange: (HotkeySettings) -> Void
    private var overlaySettings: OverlaySettings
    private let onOverlayChange: (OverlaySettings) -> Void
    private var mouseTrailSettings: MouseTrailSettings
    private let onMouseTrailChange: (MouseTrailSettings) -> Void
    private var launchAtLoginEnabled: Bool
    private let onLaunchAtLoginToggle: (Bool) -> Bool

    private var launchAtLoginCheckbox: NSButton!
    private var hotkeyEnabledCheckbox: NSButton!
    private var checkboxes: [ModifierOption: NSButton] = [:]
    private var triggerSegmented: NSSegmentedControl!
    private var colorWell: NSColorWell!
    private var lineWidthStepper: NSStepper!
    private var lineWidthLabel: NSTextField!
    private var repeatCountStepper: NSStepper!
    private var repeatCountLabel: NSTextField!
    private var trailEnabledCheckbox: NSButton!
    private var matchCursorCheckbox: NSButton!
    private var trailLengthStepper: NSStepper!
    private var trailLengthLabel: NSTextField!

    init(
        hotkeySettings: HotkeySettings,
        onHotkeyChange: @escaping (HotkeySettings) -> Void,
        overlaySettings: OverlaySettings,
        onOverlayChange: @escaping (OverlaySettings) -> Void,
        mouseTrailSettings: MouseTrailSettings,
        onMouseTrailChange: @escaping (MouseTrailSettings) -> Void,
        isLaunchAtLoginEnabled: Bool,
        onLaunchAtLoginToggle: @escaping (Bool) -> Bool
    ) {
        self.hotkeySettings = hotkeySettings
        self.onHotkeyChange = onHotkeyChange
        self.overlaySettings = overlaySettings
        self.onOverlayChange = onOverlayChange
        self.mouseTrailSettings = mouseTrailSettings
        self.onMouseTrailChange = onMouseTrailChange
        self.launchAtLoginEnabled = isLaunchAtLoginEnabled
        self.onLaunchAtLoginToggle = onLaunchAtLoginToggle

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        // MARK: General section

        launchAtLoginCheckbox = NSButton(
            checkboxWithTitle: "Launch at Login", target: self,
            action: #selector(launchAtLoginToggled(_:)))
        launchAtLoginCheckbox.state = launchAtLoginEnabled ? .on : .off

        let generalStack = NSStackView(views: [launchAtLoginCheckbox])
        generalStack.orientation = .vertical
        generalStack.alignment = .leading
        generalStack.spacing = 8

        let generalBox = makeSectionBox(title: "General", content: generalStack)

        // MARK: Hotkey section

        hotkeyEnabledCheckbox = NSButton(
            checkboxWithTitle: "Enabled", target: self,
            action: #selector(hotkeyEnabledToggled(_:)))
        hotkeyEnabledCheckbox.state = hotkeySettings.isEnabled ? .on : .off

        let modifiersCaption = NSTextField(labelWithString: "Modifiers:")
        modifiersCaption.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        modifiersCaption.textColor = .secondaryLabelColor

        let modifiersRow = NSStackView()
        modifiersRow.orientation = .horizontal
        modifiersRow.alignment = .centerY
        modifiersRow.spacing = 8
        for option in ModifierOption.allCases {
            let checkbox = NSButton(
                checkboxWithTitle: option.displayName, target: self,
                action: #selector(modifierToggled(_:)))
            checkbox.state = hotkeySettings.modifierOptions.contains(option) ? .on : .off
            checkboxes[option] = checkbox
            modifiersRow.addArrangedSubview(checkbox)
        }

        let triggerRowLabel = NSTextField(labelWithString: "Trigger on:")
        triggerSegmented = NSSegmentedControl(
            labels: ["Key Down", "Key Up"], trackingMode: .selectOne,
            target: self, action: #selector(triggerEdgeChanged(_:)))
        triggerSegmented.selectedSegment = hotkeySettings.triggerOnKeyUp ? 1 : 0
        let triggerRow = NSStackView(views: [triggerRowLabel, triggerSegmented])
        triggerRow.orientation = .horizontal
        triggerRow.alignment = .centerY
        triggerRow.spacing = 8

        let hotkeyStack = NSStackView(views: [
            hotkeyEnabledCheckbox, modifiersCaption, modifiersRow, triggerRow,
        ])
        hotkeyStack.orientation = .vertical
        hotkeyStack.alignment = .leading
        hotkeyStack.spacing = 8
        hotkeyStack.setCustomSpacing(4, after: modifiersCaption)

        let hotkeyBox = makeSectionBox(title: "Hotkey", content: hotkeyStack)

        // MARK: Appearance section

        let colorRowLabel = NSTextField(labelWithString: "Color:")
        colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 44, height: 22))
        colorWell.color = overlaySettings.color
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        let colorRow = NSStackView(views: [colorRowLabel, colorWell])
        colorRow.orientation = .horizontal
        colorRow.alignment = .centerY
        colorRow.spacing = 8

        let lineWidthRowLabel = NSTextField(labelWithString: "Line Width:")
        lineWidthStepper = NSStepper()
        lineWidthStepper.minValue = 1
        lineWidthStepper.maxValue = 20
        lineWidthStepper.increment = 1
        lineWidthStepper.valueWraps = false
        lineWidthStepper.doubleValue = Double(overlaySettings.lineWidth)
        lineWidthStepper.target = self
        lineWidthStepper.action = #selector(lineWidthChanged(_:))
        lineWidthLabel = NSTextField(labelWithString: "\(Int(overlaySettings.lineWidth))")
        lineWidthLabel.alignment = .right
        lineWidthLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let lineWidthRow = NSStackView(views: [lineWidthRowLabel, lineWidthStepper, lineWidthLabel])
        lineWidthRow.orientation = .horizontal
        lineWidthRow.alignment = .centerY
        lineWidthRow.spacing = 4

        let repeatCountRowLabel = NSTextField(labelWithString: "Repeat Count:")
        repeatCountStepper = NSStepper()
        repeatCountStepper.minValue = 1
        repeatCountStepper.maxValue = 10
        repeatCountStepper.increment = 1
        repeatCountStepper.valueWraps = false
        repeatCountStepper.integerValue = overlaySettings.repeatCount
        repeatCountStepper.target = self
        repeatCountStepper.action = #selector(repeatCountChanged(_:))
        repeatCountLabel = NSTextField(labelWithString: "\(overlaySettings.repeatCount)")
        repeatCountLabel.alignment = .right
        repeatCountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let repeatCountRow = NSStackView(views: [
            repeatCountRowLabel, repeatCountStepper, repeatCountLabel,
        ])
        repeatCountRow.orientation = .horizontal
        repeatCountRow.alignment = .centerY
        repeatCountRow.spacing = 4

        let appearanceStack = NSStackView(views: [colorRow, lineWidthRow, repeatCountRow])
        appearanceStack.orientation = .vertical
        appearanceStack.alignment = .leading
        appearanceStack.spacing = 8

        let appearanceBox = makeSectionBox(title: "Appearance", content: appearanceStack)

        // MARK: Mouse Trails section

        trailEnabledCheckbox = NSButton(
            checkboxWithTitle: "Enabled", target: self,
            action: #selector(trailEnabledToggled(_:)))
        trailEnabledCheckbox.state = mouseTrailSettings.isEnabled ? .on : .off

        matchCursorCheckbox = NSButton(
            checkboxWithTitle: "Match system cursor", target: self,
            action: #selector(matchCursorToggled(_:)))
        matchCursorCheckbox.state = mouseTrailSettings.matchesSystemCursor ? .on : .off

        let trailLengthRowLabel = NSTextField(labelWithString: "Length:")
        trailLengthStepper = NSStepper()
        trailLengthStepper.minValue = 2
        trailLengthStepper.maxValue = 20
        trailLengthStepper.increment = 1
        trailLengthStepper.valueWraps = false
        trailLengthStepper.integerValue = mouseTrailSettings.trailLength
        trailLengthStepper.target = self
        trailLengthStepper.action = #selector(trailLengthChanged(_:))
        trailLengthLabel = NSTextField(labelWithString: "\(mouseTrailSettings.trailLength)")
        trailLengthLabel.alignment = .right
        trailLengthLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let trailLengthRow = NSStackView(views: [
            trailLengthRowLabel, trailLengthStepper, trailLengthLabel,
        ])
        trailLengthRow.orientation = .horizontal
        trailLengthRow.alignment = .centerY
        trailLengthRow.spacing = 4

        let trailsStack = NSStackView(views: [
            trailEnabledCheckbox, matchCursorCheckbox, trailLengthRow,
        ])
        trailsStack.orientation = .vertical
        trailsStack.alignment = .leading
        trailsStack.spacing = 8

        let trailsBox = makeSectionBox(title: "Mouse Trails", content: trailsStack)

        // MARK: Main stack

        let boxes = [generalBox, hotkeyBox, appearanceBox, trailsBox]
        let mainStack = NSStackView(views: boxes)
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 12
        mainStack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            mainStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 380),
        ])
        // The stack's .leading alignment only pins leading edges (its own trailing
        // constraint is >=), so an equality constraint per box is what stretches
        // them all to the same full width.
        NSLayoutConstraint.activate(
            boxes.map {
                $0.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor, constant: -16)
            })
        window?.setContentSize(mainStack.fittingSize)
    }

    private func makeSectionBox(title: String, content: NSStackView) -> NSBox {
        let box = NSBox()
        box.boxType = .primary
        box.titlePosition = .atTop
        box.title = title
        // The default 5pt margins would stack with the constraints below and
        // throw off fittingSize.
        box.contentViewMargins = .zero

        content.translatesAutoresizingMaskIntoConstraints = false
        guard let host = box.contentView else { return box }
        host.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: host.topAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 10),
            content.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -10),
            content.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -10),
        ])
        return box
    }

    // MARK: - Actions

    @objc private func launchAtLoginToggled(_ sender: NSButton) {
        // The callback performs register/unregister and returns the actual
        // resulting state, so a failed registration snaps the checkbox back.
        launchAtLoginEnabled = onLaunchAtLoginToggle(sender.state == .on)
        sender.state = launchAtLoginEnabled ? .on : .off
    }

    @objc private func hotkeyEnabledToggled(_ sender: NSButton) {
        hotkeySettings.isEnabled = sender.state == .on
        onHotkeyChange(hotkeySettings)
    }

    @objc private func modifierToggled(_ sender: NSButton) {
        guard let option = checkboxes.first(where: { $0.value === sender })?.key else { return }
        if sender.state == .on {
            hotkeySettings.modifierOptions.insert(option)
        } else {
            hotkeySettings.modifierOptions.remove(option)
        }
        onHotkeyChange(hotkeySettings)
    }

    @objc private func triggerEdgeChanged(_ sender: NSSegmentedControl) {
        hotkeySettings.triggerOnKeyUp = sender.selectedSegment == 1
        onHotkeyChange(hotkeySettings)
    }

    @objc private func colorChanged(_ sender: NSColorWell) {
        overlaySettings.color = sender.color
        onOverlayChange(overlaySettings)
    }

    @objc private func lineWidthChanged(_ sender: NSStepper) {
        overlaySettings.lineWidth = CGFloat(sender.integerValue)
        lineWidthLabel.stringValue = "\(sender.integerValue)"
        onOverlayChange(overlaySettings)
    }

    @objc private func repeatCountChanged(_ sender: NSStepper) {
        overlaySettings.repeatCount = sender.integerValue
        repeatCountLabel.stringValue = "\(sender.integerValue)"
        onOverlayChange(overlaySettings)
    }

    @objc private func trailEnabledToggled(_ sender: NSButton) {
        mouseTrailSettings.isEnabled = sender.state == .on
        onMouseTrailChange(mouseTrailSettings)
    }

    @objc private func matchCursorToggled(_ sender: NSButton) {
        mouseTrailSettings.matchesSystemCursor = sender.state == .on
        onMouseTrailChange(mouseTrailSettings)
    }

    @objc private func trailLengthChanged(_ sender: NSStepper) {
        mouseTrailSettings.trailLength = sender.integerValue
        trailLengthLabel.stringValue = "\(sender.integerValue)"
        onMouseTrailChange(mouseTrailSettings)
    }

    // MARK: - External sync

    // The window is created once and reused, so a menu-bar toggle (e.g. "Hotkey Enabled")
    // made while the window is closed would otherwise leave these checkboxes stale next
    // time the window is shown.
    func syncEnabledStates(
        hotkeySettings: HotkeySettings,
        mouseTrailSettings: MouseTrailSettings,
        launchAtLoginEnabled: Bool
    ) {
        self.hotkeySettings = hotkeySettings
        self.mouseTrailSettings = mouseTrailSettings
        self.launchAtLoginEnabled = launchAtLoginEnabled
        hotkeyEnabledCheckbox.state = hotkeySettings.isEnabled ? .on : .off
        trailEnabledCheckbox.state = mouseTrailSettings.isEnabled ? .on : .off
        matchCursorCheckbox.state = mouseTrailSettings.matchesSystemCursor ? .on : .off
        launchAtLoginCheckbox.state = launchAtLoginEnabled ? .on : .off
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        NSColorPanel.shared.close()
    }
}
