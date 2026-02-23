import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let defaultTintColor: NSColor? = nil
    private var onConfigure: (() -> Void)?

    init(statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)) {
        self.statusItem = statusItem
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "MIDI PTZ")
            button.contentTintColor = defaultTintColor
        }
        statusItem.menu = menu
    }

    func updateMenu(with events: [LogEvent], onConfigure: @escaping () -> Void) {
        self.onConfigure = onConfigure
        menu.removeAllItems()

        for item in Self.menuItems(for: events) {
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let configureItem = NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: ",")
        configureItem.target = self
        menu.addItem(configureItem)
    }

    static func menuItems(for events: [LogEvent]) -> [NSMenuItem] {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium

        let recent = Array(events.suffix(5))
        if recent.isEmpty {
            let item = NSMenuItem(title: "No recent activity", action: nil, keyEquivalent: "")
            item.isEnabled = false
            return [item]
        }

        return recent.map { event in
            let time = formatter.string(from: event.timestamp)
            let title = "[\(time)] \(event.summary)"
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.isEnabled = false
            return item
        }
    }

    func flash(status: LogEventStatus) {
        guard let button = statusItem.button else { return }
        let flashColor: NSColor = (status == .ok) ? .systemGreen : .systemRed
        button.contentTintColor = flashColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak button] in
            button?.contentTintColor = self.defaultTintColor
        }
    }

    @objc private func openSettings() {
        onConfigure?()
    }
}
