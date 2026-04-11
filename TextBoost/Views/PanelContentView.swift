import SwiftUI
import AppKit

struct PanelContentView: View {
    @ObservedObject var state: ConversationState
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().opacity(0.5)

            if state.selectedPrompt != nil {
                responseSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                inputSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .frame(minWidth: 500, maxWidth: 500, minHeight: 420)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: TB.cornerLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TB.cornerLG, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: state.selectedPrompt != nil)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: TB.spacingXS) {
            if state.selectedPrompt != nil {
                Button(action: { withAnimation { state.clearResponse() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: TB.cornerXS, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let prompt = state.selectedPrompt {
                HStack(spacing: 6) {
                    Image(systemName: prompt.icon)
                        .font(.system(size: 12))
                    Text(prompt.name)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.primary.opacity(0.8))
            } else {
                Text("TextBoost")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.7))
            }

            Spacer()

            Button(action: onDismiss) {
                HStack(spacing: 6) {
                    Text("Close")
                        .font(.system(size: 13, weight: .medium))
                    KeyBadge(text: "ESC")
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, TB.spacingLG)
        .padding(.vertical, TB.spacingSM)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: TB.spacingSM) {
            // Input text area
            ZStack(alignment: .topLeading) {
                TextEditor(text: $state.inputText)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .padding(TB.spacingXS)

                if state.inputText.isEmpty {
                    Text("Enter your input text here...")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 100)
            .background(.background.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )

            // Paste from clipboard button
            Button(action: {
                if let text = NSPasteboard.general.string(forType: .string) {
                    state.inputText = text
                }
            }) {
                HStack(spacing: TB.spacingXS) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .medium))
                    Text("Paste from clipboard")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    KeyBadge(text: "\u{2318}V")
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, TB.spacingSM)
                .padding(.vertical, 10)
                .background(.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                        .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Divider with subtle style
            Rectangle()
                .fill(.primary.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, 2)

            // Prompt search and list
            PromptListView(state: state)
        }
        .padding(.horizontal, TB.spacingLG)
        .padding(.top, TB.spacingSM)
        .padding(.bottom, TB.spacingLG)
    }

    // MARK: - Response Section

    private var responseSection: some View {
        ResponseView(state: state, onDismiss: onDismiss)
            .padding(.horizontal, TB.spacingLG)
            .padding(.top, TB.spacingSM)
            .padding(.bottom, TB.spacingLG)
    }
}
