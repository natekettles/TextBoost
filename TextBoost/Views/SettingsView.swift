import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            PromptsSettingsView()
                .tabItem {
                    Label("Prompts", systemImage: "text.bubble")
                }
        }
        .frame(width: 550, height: 480)
    }
}

// MARK: - General Settings

private struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showingAnthropicKey = false
    @State private var showingOpenAIKey = false

    var body: some View {
        Form {
            Section("AI Provider") {
                Picker("Provider", selection: $settings.provider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Anthropic") {
                TextField("Model", text: $settings.anthropicModel)
                    .textFieldStyle(.roundedBorder)
                Text("e.g. claude-sonnet-4-20250514, claude-opus-4-20250514")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Anthropic API Key") {
                HStack {
                    if showingAnthropicKey {
                        TextField("sk-ant-...", text: $settings.anthropicAPIKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("sk-ant-...", text: $settings.anthropicAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(showingAnthropicKey ? "Hide" : "Show") {
                        showingAnthropicKey.toggle()
                    }
                }
                if settings.provider == .anthropic && settings.anthropicAPIKey.isEmpty {
                    Label("Required for current provider", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("OpenAI") {
                TextField("Model", text: $settings.openAIModel)
                    .textFieldStyle(.roundedBorder)
                Text("e.g. gpt-4o, gpt-4o-mini, o1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("OpenAI API Key") {
                HStack {
                    if showingOpenAIKey {
                        TextField("sk-...", text: $settings.openAIAPIKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("sk-...", text: $settings.openAIAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(showingOpenAIKey ? "Hide" : "Show") {
                        showingOpenAIKey.toggle()
                    }
                }
                if settings.provider == .openai && settings.openAIAPIKey.isEmpty {
                    Label("Required for current provider", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Text("API keys are stored securely in your Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Hotkey") {
                HStack {
                    Text("Activate TextBoost")
                    Spacer()
                    Text("Control + Space")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .formStyle(.grouped)
    }
}
