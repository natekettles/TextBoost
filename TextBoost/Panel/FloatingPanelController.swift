import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController {
    private var panel: FloatingPanel?
    private let state: ConversationState
    private let textCaptureService: TextCaptureService

    var isVisible: Bool { panel?.isVisible ?? false }

    init(textCaptureService: TextCaptureService) {
        self.textCaptureService = textCaptureService
        self.state = ConversationState(textCaptureService: textCaptureService)
    }

    func show(withText text: String?) {
        state.reset()
        if let text, !text.isEmpty {
            state.inputText = text
        }

        if panel == nil {
            createPanel()
        }

        positionPanel()
        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let rect = NSRect(x: 0, y: 0, width: 500, height: 540)
        panel = FloatingPanel(contentRect: rect)

        let hostingView = NSHostingView(
            rootView: PanelContentView(state: state) { [weak self] in
                self?.hide()
            }
        )
        panel?.contentView = hostingView
    }

    private func positionPanel() {
        guard let panel else { return }

        // Use the screen containing the mouse cursor (handles multi-monitor)
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        guard let screen else { return }

        let panelSize = panel.frame.size
        let visibleFrame = screen.visibleFrame

        let x = visibleFrame.midX - panelSize.width / 2
        let y = visibleFrame.midY - panelSize.height / 2

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
