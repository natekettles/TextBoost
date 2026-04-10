import AppKit
import os.log

private let log = Logger(subsystem: "com.nathanskidmore.TextBoost", category: "PasteService")

private let kAppActivationDelay: TimeInterval = 0.3

final class PasteService {
    func pasteText(_ text: String, into app: NSRunningApplication?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Activate the original app so it receives the paste
        if let app {
            log.info("Activating \(app.localizedName ?? "?", privacy: .public) for paste")
            app.activate(options: .activateIgnoringOtherApps)
        }

        // Wait for the app to come to the foreground, then paste via AppleScript
        DispatchQueue.main.asyncAfter(deadline: .now() + kAppActivationDelay) {
            KeyboardSimulator.simulatePaste()
        }
    }
}
