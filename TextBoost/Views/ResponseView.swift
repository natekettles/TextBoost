import SwiftUI

struct ResponseView: View {
    @ObservedObject var state: ConversationState
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Response text
            ScrollView {
                if let error = state.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    if state.responseText.isEmpty && state.isProcessing {
                        Text("Waiting for response...")
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(state.responseText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.none, value: state.responseText)
                    }
                }
            }
            .frame(maxHeight: 280)
            .padding(8)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 1)
            )

            // Loading indicator
            if state.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    state.copyResponse()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(state.responseText.isEmpty)

                Button(action: {
                    state.insertResponse(onDismiss: onDismiss)
                }) {
                    Label("Insert", systemImage: "text.insert")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(state.responseText.isEmpty || state.isProcessing)
            }
        }
    }
}
