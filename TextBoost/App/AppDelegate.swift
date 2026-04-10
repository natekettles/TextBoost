import AppKit
import Carbon
import os.log

private let log = Logger(subsystem: "com.nathanskidmore.TextBoost", category: "AppDelegate")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: HotkeyManager!
    private var panelController: FloatingPanelController!
    private let textCaptureService = TextCaptureService()
    private var hasShownPermissionAlert = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = FloatingPanelController(textCaptureService: textCaptureService)
        hotkeyManager = HotkeyManager()

        hotkeyManager.register(keyCode: 49, modifiers: UInt32(controlKey), handler: { [weak self] in
            self?.handleHotkey()
        })

        promptForAccessibility()
    }

    private func handleHotkey() {
        // Capture the frontmost app IMMEDIATELY, before any async work
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        log.info("Hotkey fired. Frontmost app: \(frontmostApp?.localizedName ?? "nil", privacy: .public) (pid: \(frontmostApp?.processIdentifier ?? 0))")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Check permissions on each hotkey press — user may have just granted them
            if !AXIsProcessTrusted() && !self.hasShownPermissionAlert {
                self.showPermissionAlert()
                return
            }

            if self.panelController.isVisible {
                self.panelController.hide()
                return
            }

            self.textCaptureService.captureSelectedText(from: frontmostApp) { [weak self] capturedText in
                log.info("Capture result: \(capturedText.map { "\($0.count) chars" } ?? "nil", privacy: .public)")
                DispatchQueue.main.async {
                    self?.panelController.show(withText: capturedText)
                }
            }
        }
    }

    private func promptForAccessibility() {
        // Log the actual binary path so we can verify it matches what's in System Settings
        let bundlePath = Bundle.main.bundlePath
        log.info("App bundle path: \(bundlePath, privacy: .public)")
        log.info("App bundle ID: \(Bundle.main.bundleIdentifier ?? "nil", privacy: .public)")

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        log.info("Accessibility trusted: \(trusted)")

        if !trusted {
            log.warning("Accessibility NOT trusted. Ensure \(bundlePath, privacy: .public) is added to System Settings → Privacy & Security → Accessibility")
        }
    }

    private func showPermissionAlert() {
        hasShownPermissionAlert = true

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "TextBoost Needs Permissions"
        alert.informativeText = """
        TextBoost needs two permissions to capture and insert text:

        1. Accessibility — to read selected text
        2. Automation (System Events) — to simulate copy/paste

        Click "Open Settings" and add TextBoost under:
        • Privacy & Security → Accessibility
        • Privacy & Security → Automation
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open Accessibility settings
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
