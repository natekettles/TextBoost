import SwiftUI

struct ResponseView: View {
    @ObservedObject var state: ConversationState
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: TB.spacingSM) {
            // Response text
            ScrollView {
                Group {
                    if let error = state.errorMessage {
                        HStack(spacing: TB.spacingXS) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red.opacity(0.8))
                            Text(error)
                                .foregroundStyle(.red.opacity(0.9))
                        }
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if state.responseText.isEmpty && state.isProcessing {
                        HStack(spacing: TB.spacingXS) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking...")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    } else {
                        Text(state.responseText)
                            .font(.system(size: 14))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.none, value: state.responseText)
                    }
                }
                .padding(TB.spacingXS)
            }
            .frame(maxHeight: 300)
            .background(.background.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous)
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            )

            // Streaming indicator
            if state.isProcessing && !state.responseText.isEmpty {
                HStack(spacing: TB.spacingXS) {
                    StreamingDots()
                    Text("Generating...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // Action buttons
            HStack(spacing: TB.spacingXS) {
                Button(action: { state.copyResponse() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                        Text("Copy")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.primary.opacity(0.06))
                    .foregroundStyle(.primary.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                            .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(state.responseText.isEmpty)

                Button(action: { state.insertResponse(onDismiss: onDismiss) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.insert")
                            .font(.system(size: 12, weight: .medium))
                        Text("Insert & Replace")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(TB.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
                    .shadow(color: TB.accent.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(state.responseText.isEmpty || state.isProcessing)
            }
        }
    }
}

// MARK: - Streaming Dots Animation

private struct StreamingDots: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(TB.accent.opacity(i <= phase ? 0.8 : 0.25))
                    .frame(width: 5, height: 5)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = (phase + 1) % 4
            }
        }
    }
}
