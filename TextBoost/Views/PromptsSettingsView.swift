import SwiftUI

struct PromptsSettingsView: View {
    @ObservedObject private var store = PromptStore.shared
    @State private var selection: UUID?
    @State private var editingPrompt: Prompt?
    @State private var isAddingNew = false
    @State private var showingResetConfirmation = false

    var body: some View {
        HSplitView {
            // Sidebar: prompt list
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(store.prompts) { prompt in
                        PromptListRow(prompt: prompt, isSelected: selection == prompt.id)
                            .tag(prompt.id)
                            .contextMenu {
                                Button("Edit...") { editingPrompt = prompt }
                                Button("Duplicate") { duplicatePrompt(prompt) }
                                Divider()
                                Button("Delete", role: .destructive) { store.delete(id: prompt.id) }
                            }
                    }
                    .onMove { source, destination in
                        store.move(from: source, to: destination)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                Divider()

                // Bottom toolbar
                HStack(spacing: 6) {
                    Button(action: startAddingPrompt) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 28, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help("Add prompt")

                    Button(action: deleteSelected) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 28, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(selection == nil)
                    .help("Delete prompt")

                    Divider()
                        .frame(height: 14)

                    Button(action: moveSelectedUp) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)
                    .help("Move up")

                    Button(action: moveSelectedDown) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)
                    .help("Move down")

                    Spacer()

                    Menu {
                        Button("Reset to Defaults...", role: .destructive) {
                            showingResetConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, TB.spacingXS)
                .padding(.vertical, 6)
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)

            // Detail: selected prompt editor or empty state
            Group {
                if let id = selection, let prompt = store.prompts.first(where: { $0.id == id }) {
                    PromptDetailView(prompt: prompt) { updated in
                        store.update(updated)
                    }
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $isAddingNew) {
            PromptEditorView(
                prompt: .constant(newPromptTemplate),
                isNew: true
            ) { updated in
                store.add(updated)
                selection = updated.id
                isAddingNew = false
            } onCancel: {
                isAddingNew = false
            }
        }
        .confirmationDialog("Reset all prompts to defaults?", isPresented: $showingResetConfirmation) {
            Button("Reset to Defaults", role: .destructive) {
                store.resetToDefaults()
                selection = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all your current prompts with the built-in defaults. This cannot be undone.")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: TB.spacingSM) {
            Image(systemName: "text.bubble")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text("Select a prompt to edit")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var newPromptTemplate: Prompt {
        Prompt(name: "", icon: "text.bubble", shortDescription: "", systemPrompt: "")
    }

    private func startAddingPrompt() {
        isAddingNew = true
    }

    private func deleteSelected() {
        guard let id = selection else { return }
        store.delete(id: id)
        selection = nil
    }

    private func duplicatePrompt(_ prompt: Prompt) {
        var copy = prompt
        copy.id = UUID()
        copy.name = "\(prompt.name) (Copy)"
        store.add(copy)
    }

    private var selectedIndex: Int? {
        guard let id = selection else { return nil }
        return store.prompts.firstIndex(where: { $0.id == id })
    }

    private var canMoveUp: Bool {
        guard let index = selectedIndex else { return false }
        return index > 0
    }

    private var canMoveDown: Bool {
        guard let index = selectedIndex else { return false }
        return index < store.prompts.count - 1
    }

    private func moveSelectedUp() {
        guard let index = selectedIndex, index > 0 else { return }
        store.move(from: IndexSet(integer: index), to: index - 1)
    }

    private func moveSelectedDown() {
        guard let index = selectedIndex, index < store.prompts.count - 1 else { return }
        store.move(from: IndexSet(integer: index), to: index + 2)
    }
}

// MARK: - Sidebar Row

private struct PromptListRow: View {
    let prompt: Prompt
    let isSelected: Bool

    private var iconColor: Color {
        let iconName = prompt.icon.isEmpty ? "text.bubble" : prompt.icon
        // Assign stable colors based on icon category
        if iconName.contains("envelope") || iconName.contains("mail") { return .blue }
        if iconName.contains("text") || iconName.contains("doc") { return .indigo }
        if iconName.contains("bubble") || iconName.contains("message") { return .purple }
        if iconName.contains("checkmark") || iconName.contains("grammar") { return .green }
        if iconName.contains("briefcase") || iconName.contains("building") { return .orange }
        if iconName.contains("face") || iconName.contains("smiley") { return .pink }
        if iconName.contains("arrow") || iconName.contains("expand") { return .red }
        if iconName.contains("list") || iconName.contains("bullet") { return .teal }
        if iconName.contains("sparkle") { return .yellow }
        return TB.accent
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: prompt.icon.isEmpty ? "text.bubble" : prompt.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? .white.opacity(0.2) : iconColor.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(prompt.shortDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Inline Detail Editor

private struct PromptDetailView: View {
    let prompt: Prompt
    let onSave: (Prompt) -> Void

    @State private var name: String
    @State private var icon: String
    @State private var shortDescription: String
    @State private var systemPrompt: String

    init(prompt: Prompt, onSave: @escaping (Prompt) -> Void) {
        self.prompt = prompt
        self.onSave = onSave
        self._name = State(initialValue: prompt.name)
        self._icon = State(initialValue: prompt.icon)
        self._shortDescription = State(initialValue: prompt.shortDescription)
        self._systemPrompt = State(initialValue: prompt.systemPrompt)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TB.spacingLG) {
                // Title area
                Text(name.isEmpty ? "Untitled Prompt" : name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(name.isEmpty ? .tertiary : .primary)

                // Form fields in a card
                VStack(alignment: .leading, spacing: TB.spacingMD) {
                    DetailRow(label: "Name") {
                        TextField("Prompt name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    DetailRow(label: "Icon") {
                        HStack(spacing: TB.spacingSM) {
                            TextField("SF Symbol name", text: $icon)
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

                    DetailRow(label: "Description") {
                        TextField("Brief description", text: $shortDescription)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: TB.spacingXS) {
                        Text("Instruction")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        TextEditor(text: $systemPrompt)
                            .font(.system(size: 13, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(TB.spacingXS)
                            .frame(minHeight: 160)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                }
                .padding(TB.spacingMD)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous)
                        .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                )
            }
            .padding(TB.spacingLG)
        }
        .onChange(of: prompt.id) { _, _ in
            name = prompt.name
            icon = prompt.icon
            shortDescription = prompt.shortDescription
            systemPrompt = prompt.systemPrompt
        }
        .onChange(of: name) { _, _ in saveIfValid() }
        .onChange(of: icon) { _, _ in saveIfValid() }
        .onChange(of: shortDescription) { _, _ in saveIfValid() }
        .onChange(of: systemPrompt) { _, _ in saveIfValid() }
    }

    private func saveIfValid() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var updated = prompt
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.icon = icon.trimmingCharacters(in: .whitespaces)
        updated.shortDescription = shortDescription.trimmingCharacters(in: .whitespaces)
        updated.systemPrompt = systemPrompt.trimmingCharacters(in: .whitespaces)
        onSave(updated)
    }
}

private struct DetailRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
            content
        }
    }
}
