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
    private var bridgeController: BridgeController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        refreshMenu()
        bridgeController = BridgeController(
            onLogEvent: { [weak self] event in
                DispatchQueue.main.async {
                    self?.appendLog(event)
                }
            },
            onFlash: { [weak self] status in
                DispatchQueue.main.async {
                    self?.statusBarController?.flash(status: status)
                }
            }
        )
        bridgeController?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        bridgeController?.stop()
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
            window.isReleasedWhenClosed = false
            window.center()
            window.contentView = NSHostingView(rootView: ContentView())
            settingsWindow = window
        }

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func appendLog(_ event: LogEvent) {
        logStore.append(event)
        refreshMenu()
    }

    private func refreshMenu() {
        statusBarController?.updateMenu(with: logStore.recentEvents, onConfigure: { [weak self] in
            self?.openSettingsWindow()
        })
    }
}
