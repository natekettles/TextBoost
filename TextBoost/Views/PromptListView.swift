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
        VStack(spacing: 8) {
            // Search field
            HStack {
                TextField("Search for a prompt or run a custom instruction...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        executeSelected()
                    }

                Image(systemName: "mic")
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 1)
            )

            // Prompt list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredPrompts.enumerated()), id: \.element.id) { index, prompt in
                            PromptRow(
                                prompt: prompt,
                                isSelected: index == selectedIndex,
                                action: { state.executePrompt(prompt) }
                            )
                            .id(prompt.id)
                        }

                        if !searchText.isEmpty && filteredPrompts.isEmpty {
                            customInstructionRow
                        }
                    }
                }
                .frame(maxHeight: 220)
                .onChange(of: selectedIndex) { _, newIndex in
                    if newIndex < filteredPrompts.count {
                        withAnimation {
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
            HStack {
                Image(systemName: "sparkles")
                Text("Run: \"\(searchText)\"")
                Spacer()
                Image(systemName: "return")
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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

/// NSView-based key event interceptor for arrow keys and Enter.
/// SwiftUI doesn't have a native way to handle these without stealing focus from the text field.
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

    override var acceptsFirstResponder: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Monitor key events locally on this window
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window == event.window else { return event }

            switch Int(event.keyCode) {
            case 126: // Up arrow
                self.onUp?()
                return nil // consume the event
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
}

// MARK: - Prompt Row

private struct PromptRow: View {
    let prompt: Prompt
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: prompt.icon)
                    .frame(width: 20)
                Text(prompt.name)
                    .fontWeight(isSelected ? .medium : .regular)
                Spacer()
                Image(systemName: isSelected ? "return" : "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
