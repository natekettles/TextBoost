import SwiftUI
import AppKit

struct PanelContentView: View {
    @ObservedObject var state: ConversationState
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar
            Divider()

            // Content
            if state.selectedPrompt != nil {
                responseSection
            } else {
                inputSection
            }
        }
        .frame(minWidth: 460, maxWidth: 460, minHeight: 400)
        .background(.regularMaterial)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if state.selectedPrompt != nil {
                Button(action: { state.clearResponse() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text("TextBoost")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 12) {
                Button("Close") { onDismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                Text("ESC")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 12) {
            // Input text area
            TextEditor(text: $state.inputText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 1)
                )
                .frame(height: 100)
                .overlay(alignment: .topLeading) {
                    if state.inputText.isEmpty {
                        Text("Enter your input text here...")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            // Paste from clipboard button
            Button(action: {
                if let text = NSPasteboard.general.string(forType: .string) {
                    state.inputText = text
                }
            }) {
                HStack {
                    Image(systemName: "doc.on.clipboard")
                    Text("Paste from clipboard")
                    Spacer()
                    Text("\u{2318}V")
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Divider()

            // Prompt search and list
            PromptListView(state: state)
        }
        .padding(16)
    }

    // MARK: - Response Section

    private var responseSection: some View {
        VStack(spacing: 12) {
            if let prompt = state.selectedPrompt {
                HStack {
                    Image(systemName: prompt.icon)
                    Text(prompt.name)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }

            ResponseView(state: state, onDismiss: onDismiss)
        }
        .padding(16)
    }
}
