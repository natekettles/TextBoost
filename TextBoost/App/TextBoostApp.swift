import SwiftUI

@main
struct TextBoostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("TextBoost", image: "MenuBarIcon") {
            Button("Settings...") {
                showInDock(true)
                openWindow(id: "settings")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.activate()
                    NSApp.windows
                        .first { $0.identifier?.rawValue.contains("settings") == true }?
                        .makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut(",", modifiers: .command)
            Divider()
            Button("Quit TextBoost") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        Window("TextBoost Settings", id: "settings") {
            SettingsView()
                .onDisappear {
                    showInDock(false)
                }
        }
        .defaultSize(width: 900, height: 560)
        .windowResizability(.contentMinSize)
    }

    private func showInDock(_ show: Bool) {
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }
}
