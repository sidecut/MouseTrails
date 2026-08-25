import AppKit

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private var hotkeySettings: HotkeySettings
    private let onHotkeyChange: (HotkeySettings) -> Void
    private var overlaySettings: OverlaySettings
    private let onOverlayChange: (OverlaySettings) -> Void
    private var mouseTrailSettings: MouseTrailSettings
    private let onMouseTrailChange: (MouseTrailSettings) -> Void

    private var hotkeyEnabledCheckbox: NSButton!
    private var checkboxes: [ModifierOption: NSButton] = [:]
    private var keyDownRadio: NSButton!
    private var keyUpRadio: NSButton!
    private var colorWell: NSColorWell!
    private var lineWidthStepper: NSStepper!
    private var lineWidthLabel: NSTextField!
    private var repeatCountStepper: NSStepper!
    private var repeatCountLabel: NSTextField!
    private var trailEnabledCheckbox: NSButton!
    private var trailLengthStepper: NSStepper!
    private var trailLengthLabel: NSTextField!

    init(
        hotkeySettings: HotkeySettings,
        onHotkeyChange: @escaping (HotkeySettings) -> Void,
        overlaySettings: OverlaySettings,
        onOverlayChange: @escaping (OverlaySettings) -> Void,
        mouseTrailSettings: MouseTrailSettings,
        onMouseTrailChange: @escaping (MouseTrailSettings) -> Void
    ) {
        self.hotkeySettings = hotkeySettings
        self.onHotkeyChange = onHotkeyChange
        self.overlaySettings = overlaySettings
        self.onOverlayChange = onOverlayChange
        self.mouseTrailSettings = mouseTrailSettings
        self.onMouseTrailChange = onMouseTrailChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 300),
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

        // MARK: Hotkey section

        hotkeyEnabledCheckbox = NSButton(
            checkboxWithTitle: "Hotkey Enabled", target: self,
            action: #selector(hotkeyEnabledToggled(_:)))
        hotkeyEnabledCheckbox.state = hotkeySettings.isEnabled ? .on : .off

        let modifiersLabel = NSTextField(labelWithString: "Trigger modifiers:")
        modifiersLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        let checkboxStack = NSStackView()
        checkboxStack.orientation = .vertical
        checkboxStack.alignment = .leading
        checkboxStack.spacing = 4

        for option in ModifierOption.allCases {
            let checkbox = NSButton(
                checkboxWithTitle: option.displayName, target: self,
                action: #selector(modifierToggled(_:)))
            checkbox.state = hotkeySettings.modifierOptions.contains(option) ? .on : .off
            checkboxes[option] = checkbox
            checkboxStack.addArrangedSubview(checkbox)
        }

        let edgeLabel = NSTextField(labelWithString: "Trigger on:")
        edgeLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        keyDownRadio = NSButton(
            radioButtonWithTitle: "Key Down", target: self, action: #selector(edgeChanged(_:)))
        keyUpRadio = NSButton(
            radioButtonWithTitle: "Key Up", target: self, action: #selector(edgeChanged(_:)))
        keyDownRadio.state = hotkeySettings.triggerOnKeyUp ? .off : .on
        keyUpRadio.state = hotkeySettings.triggerOnKeyUp ? .on : .off

        let edgeStack = NSStackView(views: [keyDownRadio, keyUpRadio])
        edgeStack.orientation = .vertical
        edgeStack.alignment = .leading
        edgeStack.spacing = 4

        // MARK: Appearance section

        let appearanceLabel = NSTextField(labelWithString: "Appearance:")
        appearanceLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        // Color row
        let colorRowLabel = NSTextField(labelWithString: "Color:")
        colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 44, height: 22))
        colorWell.color = overlaySettings.color
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        let colorRow = NSStackView(views: [colorRowLabel, colorWell])
        colorRow.orientation = .horizontal
        colorRow.alignment = .centerY
        colorRow.spacing = 8

        // Line width row
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

        // Repeat count row
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
        let repeatCountRow = NSStackView(views: [repeatCountRowLabel, repeatCountStepper, repeatCountLabel])
        repeatCountRow.orientation = .horizontal
        repeatCountRow.alignment = .centerY
        repeatCountRow.spacing = 4

        let appearanceStack = NSStackView(views: [colorRow, lineWidthRow, repeatCountRow])
        appearanceStack.orientation = .vertical
        appearanceStack.alignment = .leading
        appearanceStack.spacing = 8

        // MARK: Mouse Trails section

        let trailsLabel = NSTextField(labelWithString: "Mouse Trails:")
        trailsLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        trailEnabledCheckbox = NSButton(
            checkboxWithTitle: "Enable Mouse Trails", target: self,
            action: #selector(trailEnabledToggled(_:)))
        trailEnabledCheckbox.state = mouseTrailSettings.isEnabled ? .on : .off

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

        let trailsStack = NSStackView(views: [trailEnabledCheckbox, trailLengthRow])
        trailsStack.orientation = .vertical
        trailsStack.alignment = .leading
        trailsStack.spacing = 8

        // MARK: Main stack

        let mainStack = NSStackView(views: [
            hotkeyEnabledCheckbox, modifiersLabel, checkboxStack, edgeLabel, edgeStack,
            appearanceLabel, appearanceStack,
            trailsLabel, trailsStack,
        ])
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
            mainStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
        ])
        window?.setContentSize(mainStack.fittingSize)
    }

    // MARK: - Actions

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

    @objc private func edgeChanged(_ sender: NSButton) {
        hotkeySettings.triggerOnKeyUp = (sender === keyUpRadio)
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

    @objc private func trailLengthChanged(_ sender: NSStepper) {
        mouseTrailSettings.trailLength = sender.integerValue
        trailLengthLabel.stringValue = "\(sender.integerValue)"
        onMouseTrailChange(mouseTrailSettings)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        NSColorPanel.shared.close()
    }
}
