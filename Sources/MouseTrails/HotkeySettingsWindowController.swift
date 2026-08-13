import AppKit

final class HotkeySettingsWindowController: NSWindowController {
    private var settings: HotkeySettings
    private let onChange: (HotkeySettings) -> Void
    private var checkboxes: [ModifierOption: NSButton] = [:]
    private var keyDownRadio: NSButton!
    private var keyUpRadio: NSButton!

    init(settings: HotkeySettings, onChange: @escaping (HotkeySettings) -> Void) {
        self.settings = settings
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hotkey Settings"
        window.isReleasedWhenClosed = false

        super.init(window: window)
        buildUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

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
            checkbox.state = settings.modifierOptions.contains(option) ? .on : .off
            checkboxes[option] = checkbox
            checkboxStack.addArrangedSubview(checkbox)
        }

        let edgeLabel = NSTextField(labelWithString: "Trigger on:")
        edgeLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        keyDownRadio = NSButton(
            radioButtonWithTitle: "Key Down", target: self, action: #selector(edgeChanged(_:)))
        keyUpRadio = NSButton(
            radioButtonWithTitle: "Key Up", target: self, action: #selector(edgeChanged(_:)))
        keyDownRadio.state = settings.triggerOnKeyUp ? .off : .on
        keyUpRadio.state = settings.triggerOnKeyUp ? .on : .off

        let edgeStack = NSStackView(views: [keyDownRadio, keyUpRadio])
        edgeStack.orientation = .vertical
        edgeStack.alignment = .leading
        edgeStack.spacing = 4

        let mainStack = NSStackView(views: [
            modifiersLabel, checkboxStack, edgeLabel, edgeStack,
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
            // Wide enough that the "Hotkey Settings" title bar text isn't clipped —
            // the checkbox/radio content alone fits a much narrower window.
            mainStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
        ])
        window?.setContentSize(mainStack.fittingSize)
    }

    @objc private func modifierToggled(_ sender: NSButton) {
        guard let option = checkboxes.first(where: { $0.value === sender })?.key else { return }
        if sender.state == .on {
            settings.modifierOptions.insert(option)
        } else {
            settings.modifierOptions.remove(option)
        }
        onChange(settings)
    }

    @objc private func edgeChanged(_ sender: NSButton) {
        settings.triggerOnKeyUp = (sender === keyUpRadio)
        onChange(settings)
    }
}
