import SwiftUI

struct PromptsSettingsView: View {
    @ObservedObject private var store = PromptStore.shared
    @State private var selection: UUID?
    @State private var editingPrompt: Prompt?
    @State private var isAddingNew = false
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Prompt list with drag reordering
            List(selection: $selection) {
                ForEach(store.prompts) { prompt in
                    HStack(spacing: 10) {
                        Image(systemName: prompt.icon.isEmpty ? "text.bubble" : prompt.icon)
                            .frame(width: 20)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(prompt.name)
                                .fontWeight(.medium)
                            Text(prompt.shortDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
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
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            // Toolbar
            HStack(spacing: 8) {
                Button(action: { startAddingPrompt() }) {
                    Image(systemName: "plus")
                }
                .help("Add prompt")

                Button(action: deleteSelected) {
                    Image(systemName: "minus")
                }
                .help("Delete prompt")
                .disabled(selection == nil)

                Divider()
                    .frame(height: 16)

                Button(action: editSelected) {
                    Image(systemName: "pencil")
                }
                .help("Edit prompt")
                .disabled(selection == nil)

                Button(action: moveSelectedUp) {
                    Image(systemName: "arrow.up")
                }
                .help("Move up")
                .disabled(!canMoveUp)

                Button(action: moveSelectedDown) {
                    Image(systemName: "arrow.down")
                }
                .help("Move down")
                .disabled(!canMoveDown)

                Spacer()

                Button("Reset to Defaults") { showingResetConfirmation = true }
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .sheet(item: $editingPrompt) { prompt in
            promptEditor(for: prompt, isNew: false)
        }
        .sheet(isPresented: $isAddingNew) {
            promptEditor(for: newPromptTemplate, isNew: true)
        }
        .confirmationDialog("Reset all prompts to defaults?", isPresented: $showingResetConfirmation) {
            Button("Reset to Defaults", role: .destructive) {
                store.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all your current prompts with the built-in defaults. This cannot be undone.")
        }
    }

    // MARK: - Editor sheets

    private var newPromptTemplate: Prompt {
        Prompt(name: "", icon: "text.bubble", shortDescription: "", systemPrompt: "")
    }

    private func promptEditor(for prompt: Prompt, isNew: Bool) -> some View {
        let binding = Binding<Prompt>(
            get: { prompt },
            set: { _ in }
        )
        return PromptEditorView(prompt: binding, isNew: isNew) { updated in
            if isNew {
                store.add(updated)
            } else {
                store.update(updated)
            }
            editingPrompt = nil
            isAddingNew = false
        } onCancel: {
            editingPrompt = nil
            isAddingNew = false
        }
    }

    // MARK: - Actions

    private func startAddingPrompt() {
        isAddingNew = true
    }

    private func deleteSelected() {
        guard let id = selection else { return }
        store.delete(id: id)
        selection = nil
    }

    private func editSelected() {
        guard let id = selection, let prompt = store.prompts.first(where: { $0.id == id }) else { return }
        editingPrompt = prompt
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
