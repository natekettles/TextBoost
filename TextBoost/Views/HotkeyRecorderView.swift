import SwiftUI
import Carbon

struct HotkeyRecorderView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isRecording = false

    var body: some View {
        Button(action: { isRecording = true }) {
            HStack(spacing: 6) {
                if isRecording {
                    Text("Press a key combo...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TB.accent)
                } else {
                    let display = HotkeyDisplay.from(
                        keyCode: settings.hotkeyKeyCode,
                        modifiers: settings.hotkeyModifiers
                    )
                    ForEach(display.modifierSymbols, id: \.self) { symbol in
                        KeyBadge(text: symbol)
                    }
                    KeyBadge(text: display.keyName)
                }
            }
            .padding(.horizontal, TB.spacingSM)
            .padding(.vertical, 7)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                    .fill(isRecording ? TB.accent.opacity(0.08) : .primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                    .strokeBorder(isRecording ? TB.accent.opacity(0.4) : .primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .background(
            HotkeyInterceptor(isRecording: $isRecording) { keyCode, modifiers in
                settings.hotkeyKeyCode = keyCode
                settings.hotkeyModifiers = modifiers
            }
        )
    }
}

// MARK: - Key Event Interceptor

private struct HotkeyInterceptor: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onRecord: (Int, Int) -> Void

    func makeNSView(context: Context) -> HotkeyInterceptorNSView {
        let view = HotkeyInterceptorNSView()
        view.onRecord = { keyCode, modifiers in
            onRecord(keyCode, modifiers)
            isRecording = false
        }
        view.onCancel = { isRecording = false }
        return view
    }

    func updateNSView(_ nsView: HotkeyInterceptorNSView, context: Context) {
        if isRecording {
            nsView.startRecording()
        } else {
            nsView.stopRecording()
        }
    }
}

private class HotkeyInterceptorNSView: NSView {
    var onRecord: ((Int, Int) -> Void)?
    var onCancel: (() -> Void)?
    private var monitor: Any?

    func startRecording() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // Escape cancels recording
            if event.keyCode == 53 {
                self.onCancel?()
                return nil
            }

            // Require at least one modifier (prevent bare keys)
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let carbonMods = mods.carbonModifiers
            guard carbonMods != 0 else { return nil }

            self.onRecord?(Int(event.keyCode), carbonMods)
            return nil
        }
    }

    func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stopRecording()
    }
}

// MARK: - Modifier Flags → Carbon

private extension NSEvent.ModifierFlags {
    var carbonModifiers: Int {
        var result = 0
        if contains(.control) { result |= controlKey }
        if contains(.option) { result |= optionKey }
        if contains(.shift) { result |= shiftKey }
        if contains(.command) { result |= cmdKey }
        return result
    }
}

// MARK: - Display Helpers

struct HotkeyDisplay {
    let modifierSymbols: [String]
    let keyName: String

    static func from(keyCode: Int, modifiers: Int) -> HotkeyDisplay {
        var symbols: [String] = []
        if modifiers & controlKey != 0 { symbols.append("\u{2303}") }  // ⌃
        if modifiers & optionKey != 0 { symbols.append("\u{2325}") }   // ⌥
        if modifiers & shiftKey != 0 { symbols.append("\u{21E7}") }    // ⇧
        if modifiers & cmdKey != 0 { symbols.append("\u{2318}") }      // ⌘

        return HotkeyDisplay(
            modifierSymbols: symbols,
            keyName: keyCodeName(keyCode)
        )
    }

    private static func keyCodeName(_ code: Int) -> String {
        switch code {
        // Letters
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"

        // Numbers
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"

        // Special keys
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 53: return "Escape"

        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"

        // Punctuation
        case 27: return "-"
        case 24: return "="
        case 33: return "["
        case 30: return "]"
        case 42: return "\\"
        case 41: return ";"
        case 39: return "'"
        case 43: return ","
        case 47: return "."
        case 44: return "/"
        case 50: return "`"

        // Arrow keys
        case 123: return "\u{2190}" // ←
        case 124: return "\u{2192}" // →
        case 125: return "\u{2193}" // ↓
        case 126: return "\u{2191}" // ↑

        default: return "Key \(code)"
        }
    }
}
