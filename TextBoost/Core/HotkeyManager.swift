import Carbon
import Foundation
import os.log

private let log = Logger(subsystem: "com.nathanskidmore.TextBoost", category: "HotkeyManager")

/// Hotkey signature: "TB" (TextBoost) as a 4-byte OSType
private let kHotkeySignature: OSType = 0x5442

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var handler: (() -> Void)?

    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.handler = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Pass self as user data so the C callback can route back to this instance
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handler?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )

        if installStatus != noErr {
            log.error("Failed to install event handler: \(installStatus)")
            return
        }

        let hotkeyID = EventHotKeyID(signature: kHotkeySignature, id: 1)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            log.error("Failed to register hotkey: \(registerStatus)")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
        handler = nil
    }

    deinit {
        unregister()
    }
}
