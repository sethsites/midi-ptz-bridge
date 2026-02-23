import AppKit
import SwiftUI

@main
struct MIDI_PTZ_BridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var logStore = LogStore()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        statusBarController?.updateMenu(with: logStore.recentEvents, onConfigure: { [weak self] in
            self?.openSettingsWindow()
        })
    }

    private func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MIDI PTZ Bridge"
            window.center()
            window.contentView = NSHostingView(rootView: ContentView())
            settingsWindow = window
        }

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }
}
