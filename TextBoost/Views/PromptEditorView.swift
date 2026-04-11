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
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isNew ? "New Prompt" : "Edit Prompt")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, TB.spacingLG)
            .padding(.top, TB.spacingLG)
            .padding(.bottom, TB.spacingSM)

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: TB.spacingMD) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextField("Prompt name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Icon")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        HStack(spacing: TB.spacingSM) {
                            TextField("SF Symbol name (e.g. envelope)", text: $icon)
                                .textFieldStyle(.roundedBorder)
                            if !icon.isEmpty {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(TB.accent)
                                    .frame(width: 32, height: 32)
                                    .background(TB.accent.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: TB.cornerXS, style: .continuous))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextField("Brief description", text: $shortDescription)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Prompt")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $systemPrompt)
                            .font(.system(size: 13, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(TB.spacingXS)
                            .frame(minHeight: 140)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
                .padding(TB.spacingLG)
            }

            Divider()

            // Footer buttons
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(isNew ? "Add Prompt" : "Save") {
                    var updated = prompt
                    updated.name = name.trimmingCharacters(in: .whitespaces)
                    updated.icon = icon.trimmingCharacters(in: .whitespaces)
                    updated.shortDescription = shortDescription.trimmingCharacters(in: .whitespaces)
                    updated.systemPrompt = systemPrompt.trimmingCharacters(in: .whitespaces)
                    onSave(updated)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
                .tint(TB.accent)
            }
            .padding(.horizontal, TB.spacingLG)
            .padding(.vertical, TB.spacingSM)
        }
        .frame(minWidth: 480, maxWidth: 480, minHeight: 440)
    }
}
