import SwiftUI

struct PromptEditorView: View {
    @Binding var prompt: Prompt
    let isNew: Bool
    let onSave: (Prompt) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var icon: String
    @State private var shortDescription: String
    @State private var systemPrompt: String

    init(prompt: Binding<Prompt>, isNew: Bool, onSave: @escaping (Prompt) -> Void, onCancel: @escaping () -> Void) {
        self._prompt = prompt
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        self._name = State(initialValue: prompt.wrappedValue.name)
        self._icon = State(initialValue: prompt.wrappedValue.icon)
        self._shortDescription = State(initialValue: prompt.wrappedValue.shortDescription)
        self._systemPrompt = State(initialValue: prompt.wrappedValue.systemPrompt)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !systemPrompt.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isNew ? "New Prompt" : "Edit Prompt")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                TextField("SF Symbol icon (e.g. envelope)", text: $icon)
                HStack(spacing: 8) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .frame(width: 20)
                    }
                    Text("Preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Short description", text: $shortDescription)

                VStack(alignment: .leading, spacing: 4) {
                    Text("System prompt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $systemPrompt)
                        .font(.body.monospaced())
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.separator, lineWidth: 1)
                        )
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(isNew ? "Add" : "Save") {
                    var updated = prompt
                    updated.name = name.trimmingCharacters(in: .whitespaces)
                    updated.icon = icon.trimmingCharacters(in: .whitespaces)
                    updated.shortDescription = shortDescription.trimmingCharacters(in: .whitespaces)
                    updated.systemPrompt = systemPrompt.trimmingCharacters(in: .whitespaces)
                    onSave(updated)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(minWidth: 500, maxWidth: 500, minHeight: 400)
    }
}
