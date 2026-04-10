import AppKit
import os.log

private let log = Logger(subsystem: "com.nathanskidmore.TextBoost", category: "TextCapture")

private let kClipboardPollInterval: TimeInterval = 0.05
private let kClipboardMaxWait: TimeInterval = 1.0
private let kKeyReleaseDelay: TimeInterval = 0.15

final class TextCaptureService {
    /// The app that was frontmost when we captured text — needed to paste back into it later.
    private(set) var previousApp: NSRunningApplication?

    func captureSelectedText(from frontmostApp: NSRunningApplication?, completion: @escaping (String?) -> Void) {
        previousApp = frontmostApp
        let appName = frontmostApp?.localizedName ?? "nil"
        log.info("Capture starting — app: \(appName, privacy: .public), AXTrusted: \(AXIsProcessTrusted())")

        // Strategy 1: Accessibility API (instant, non-destructive)
        if let text = captureViaAccessibility(from: frontmostApp) {
            log.info("AX succeeded (\(text.count) chars)")
            completion(text)
            return
        }

        // Strategy 2: AppleScript Cmd+C via System Events (reliable, uses clipboard)
        log.info("AX failed, falling back to AppleScript Cmd+C")
        captureViaAppleScript(targetApp: frontmostApp, completion: completion)
    }

    // MARK: - Accessibility Capture

    private func captureViaAccessibility(from app: NSRunningApplication?) -> String? {
        // Try system-wide focused element first
        let systemWide = AXUIElementCreateSystemWide()
        if let text = selectedText(from: systemWide, strategy: "system-wide") {
            return text
        }

        // Try app-specific
        guard let app else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        if let text = selectedText(from: axApp, strategy: "app(\(app.localizedName ?? "?"))") {
            return text
        }

        return nil
    }

    private func selectedText(from root: AXUIElement, strategy: String) -> String? {
        var focusedRef: CFTypeRef?
        let focusErr = AXUIElementCopyAttributeValue(root, kAXFocusedUIElementAttribute as CFString, &focusedRef)

        guard focusErr == .success, let focusedRef else {
            log.info("\(strategy, privacy: .public): no focused element (AXError \(focusErr.rawValue))")
            return nil
        }

        let element = focusedRef as! AXUIElement

        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        log.info("\(strategy, privacy: .public): focused element role=\(role as? String ?? "?", privacy: .public)")

        var textRef: CFTypeRef?
        let textErr = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &textRef)

        if textErr == .success, let text = textRef as? String, !text.isEmpty {
            return text
        }

        log.info("\(strategy, privacy: .public): no selected text (AXError \(textErr.rawValue))")
        return nil
    }

    // MARK: - AppleScript Clipboard Capture

    private func captureViaAppleScript(targetApp: NSRunningApplication?, completion: @escaping (String?) -> Void) {
        let pasteboard = NSPasteboard.general
        let savedContents = pasteboard.string(forType: .string)

        // Clear clipboard so we can detect new content
        pasteboard.clearContents()
        let changeCountAfterClear = pasteboard.changeCount

        // Make sure the target app is frontmost
        if let app = targetApp, !app.isActive {
            log.info("Re-activating \(app.localizedName ?? "?", privacy: .public)")
            app.activate(options: .activateIgnoringOtherApps)
        }

        // Wait for key release + app activation, then send Cmd+C via AppleScript
        DispatchQueue.main.asyncAfter(deadline: .now() + kKeyReleaseDelay) {
            KeyboardSimulator.simulateCopy()

            // Poll for clipboard to change
            let startTime = DispatchTime.now()

            func poll() {
                if pasteboard.changeCount != changeCountAfterClear,
                   let content = pasteboard.string(forType: .string), !content.isEmpty {
                    log.info("AppleScript capture succeeded (\(content.count) chars)")
                    completion(content)
                    return
                }

                let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
                if elapsed < kClipboardMaxWait {
                    DispatchQueue.main.asyncAfter(deadline: .now() + kClipboardPollInterval) {
                        poll()
                    }
                } else {
                    log.warning("AppleScript capture timed out after \(elapsed, format: .fixed(precision: 2))s")
                    // Restore original clipboard
                    if let savedContents {
                        pasteboard.clearContents()
                        pasteboard.setString(savedContents, forType: .string)
                    }
                    completion(nil)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + kClipboardPollInterval) {
                poll()
            }
        }
    }
}
