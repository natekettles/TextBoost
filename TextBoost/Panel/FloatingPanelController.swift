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
        let rect = NSRect(x: 0, y: 0, width: 480, height: 520)
        panel = FloatingPanel(contentRect: rect)

        let hostingView = NSHostingView(
            rootView: PanelContentView(state: state) { [weak self] in
                self?.hide()
            }
        )
        panel?.contentView = hostingView
    }

    private func positionPanel() {
        guard let panel, let screen = NSScreen.main else { return }

        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size
        let visibleFrame = screen.visibleFrame

        var x = mouseLocation.x - panelSize.width / 2
        var y = mouseLocation.y - panelSize.height / 2

        // Clamp to screen bounds
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - panelSize.width))
        y = max(visibleFrame.minY, min(y, visibleFrame.maxY - panelSize.height))

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
