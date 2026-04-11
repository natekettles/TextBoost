import SwiftUI

struct PromptListView: View {
    @ObservedObject var state: ConversationState
    @ObservedObject private var store = PromptStore.shared
    @State private var searchText = ""
    @State private var selectedIndex = 0

    private var filteredPrompts: [Prompt] {
        store.search(searchText)
    }

    var body: some View {
        VStack(spacing: TB.spacingXS) {
            // Search field
            HStack(spacing: TB.spacingXS) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)

                TextField("Search prompts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        executeSelected()
                    }
            }
            .padding(.horizontal, TB.spacingSM)
            .padding(.vertical, 9)
            .background(.background.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )

            // Prompt list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(Array(filteredPrompts.enumerated()), id: \.element.id) { index, prompt in
                            PromptRow(
                                prompt: prompt,
                                isSelected: index == selectedIndex,
                                action: { state.executePrompt(prompt) }
                            )
                            .id(prompt.id)
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = index
                                }
                            }
                        }

                        if !searchText.isEmpty && filteredPrompts.isEmpty {
                            customInstructionRow
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 230)
                .onChange(of: selectedIndex) { _, newIndex in
                    if newIndex < filteredPrompts.count {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(filteredPrompts[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
        .background(
            KeyboardHandlerView(
                onUp: { moveSelection(-1) },
                onDown: { moveSelection(1) },
                onEnter: { executeSelected() }
            )
        )
    }

    private func moveSelection(_ delta: Int) {
        let count = filteredPrompts.count
        guard count > 0 else { return }
        selectedIndex = max(0, min(count - 1, selectedIndex + delta))
    }

    private func executeSelected() {
        if !filteredPrompts.isEmpty {
            let index = min(selectedIndex, filteredPrompts.count - 1)
            state.executePrompt(filteredPrompts[index])
        } else if !searchText.isEmpty {
            executeCustomInstruction()
        }
    }

    private var customInstructionRow: some View {
        Button(action: executeCustomInstruction) {
            HStack(spacing: TB.spacingXS) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                Text("Run: \"\(searchText)\"")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                KeyBadge(text: "\u{21B5}")
            }
            .padding(.horizontal, TB.spacingSM)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(TB.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func executeCustomInstruction() {
        let customPrompt = Prompt(
            name: searchText,
            icon: "sparkles",
            shortDescription: "Custom instruction",
            systemPrompt: searchText
        )
        state.executePrompt(customPrompt)
    }
}

// MARK: - Keyboard Handler

private struct KeyboardHandlerView: NSViewRepresentable {
    let onUp: () -> Void
    let onDown: () -> Void
    let onEnter: () -> Void

    func makeNSView(context: Context) -> KeyInterceptorView {
        let view = KeyInterceptorView()
        view.onUp = onUp
        view.onDown = onDown
        view.onEnter = onEnter
        return view
    }

    func updateNSView(_ nsView: KeyInterceptorView, context: Context) {
        nsView.onUp = onUp
        nsView.onDown = onDown
        nsView.onEnter = onEnter
    }
}

class KeyInterceptorView: NSView {
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onEnter: (() -> Void)?

    private var monitor: Any?

    override var acceptsFirstResponder: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        // Clean up any existing monitor
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil

        guard window != nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window == event.window else { return event }

            switch Int(event.keyCode) {
            case 126: // Up arrow
                self.onUp?()
                return nil
            case 125: // Down arrow
                self.onDown?()
                return nil
            case 36: // Return/Enter
                self.onEnter?()
                return nil
            default:
                return event
            }
        }
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview == nil, let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}

// MARK: - Prompt Row

private struct PromptRow: View {
    let prompt: Prompt
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TB.spacingSM) {
                Image(systemName: prompt.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 22, height: 22)
                    .background(
                        isSelected
                            ? AnyShapeStyle(.white.opacity(0.2))
                            : AnyShapeStyle(.primary.opacity(0.05))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: TB.cornerXS, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(prompt.name)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    Text(prompt.shortDescription)
                        .font(.system(size: 11))
                        .opacity(isSelected ? 0.75 : 0.45)
                }

                Spacer()

                if isSelected {
                    KeyBadge(text: "\u{21B5}")
                        .opacity(0.8)
                }
            }
            .padding(.horizontal, TB.spacingSM)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(TB.accentGradient) : AnyShapeStyle(.clear))
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .contentShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}
