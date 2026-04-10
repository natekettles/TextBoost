import AppKit
import os.log

private let log = Logger(subsystem: "com.nathanskidmore.TextBoost", category: "KeyboardSim")

/// Simulates keyboard shortcuts (Cmd+C, Cmd+V) via AppleScript → System Events.
/// This is more reliable than CGEvent.post() because System Events handles
/// the event routing to the correct app.
enum KeyboardSimulator {

    /// Simulates Cmd+C in the frontmost app via System Events.
    static func simulateCopy() {
        runKeystroke("c")
    }

    /// Simulates Cmd+V in the frontmost app via System Events.
    static func simulatePaste() {
        runKeystroke("v")
    }

    private static func runKeystroke(_ key: String) {
        let script = """
        tell application "System Events"
            keystroke "\(key)" using command down
        end tell
        """

        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&error)

        if let error {
            log.error("AppleScript keystroke '\(key, privacy: .public)' failed: \(error, privacy: .public)")
        } else {
            log.info("AppleScript keystroke '\(key, privacy: .public)' sent")
        }
    }
}
