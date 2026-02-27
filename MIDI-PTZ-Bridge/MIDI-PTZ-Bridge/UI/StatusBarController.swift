import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let defaultTintColor: NSColor? = .systemBlue
    private var onConfigure: (() -> Void)?
    private var redImage: NSImage? = nil
    private var greenImage: NSImage? = nil
    private var baseImage: NSImage? = nil
    

    init(statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)) {
        self.statusItem = statusItem
        self.redImage = coloredCircleFillImage(color: NSColor.systemRed, size: NSMakeSize(20, 20))
        self.greenImage = coloredCircleFillImage(color: NSColor.systemGreen, size: NSMakeSize(20, 20))
        self.baseImage = coloredCircleFillImage(color: NSColor.systemBlue, size: NSMakeSize(20, 20))
        
        if let button = statusItem.button {
            button.image = self.baseImage
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
        let flashImage: NSImage? = (status == .ok) ? greenImage : redImage
        button.image = flashImage
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak button] in
            button?.image = self.baseImage
        }
    }
    
    func coloredCircleFillImage(color: NSColor, size: NSSize) -> NSImage? {
        let symbolConfiguration = NSImage.SymbolConfiguration(paletteColors: [color])
        
        guard let baseImage = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "MIDI PTZ") else {
            return nil
        }
        
        let coloredImage = baseImage.withSymbolConfiguration(symbolConfiguration)
        
        if let sizedImage = coloredImage {
            sizedImage.size = size
            return sizedImage
        }
        
        return coloredImage
    }

    @objc private func openSettings() {
        onConfigure?()
    }
}
