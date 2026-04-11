import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            tabBar
            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .prompts:
                    PromptsSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 750, minHeight: 480)
    }

    private var tabBar: some View {
        HStack(spacing: TB.spacingXL) {
            ForEach(SettingsTab.allCases) { tab in
                SettingsTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.vertical, TB.spacingSM)
    }
}

// MARK: - Tab Model

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case prompts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .prompts: return "Prompts"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .prompts: return "text.bubble"
        }
    }
}

// MARK: - Tab Button

private struct SettingsTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                Text(tab.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? TB.accent : .secondary)
            .padding(.horizontal, TB.spacingMD)
            .padding(.vertical, TB.spacingXS)
            .background(
                isSelected
                    ? TB.accent.opacity(0.08)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: TB.cornerSM, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Settings

private struct GeneralSettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showingAnthropicKey = false
    @State private var showingOpenAIKey = false

    var body: some View {
        ScrollView {
            VStack(spacing: TB.spacingLG) {
                // Provider Selection
                SettingsSection(title: "AI Provider") {
                    Picker("Provider", selection: $settings.provider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                // Anthropic Config
                SettingsSection(title: "Anthropic") {
                    VStack(alignment: .leading, spacing: TB.spacingSM) {
                        SettingsField(label: "Model") {
                            TextField("claude-sonnet-4-20250514", text: $settings.anthropicModel)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingsField(label: "API Key") {
                            HStack(spacing: TB.spacingXS) {
                                Group {
                                    if showingAnthropicKey {
                                        TextField("sk-ant-...", text: $settings.anthropicAPIKey)
                                    } else {
                                        SecureField("sk-ant-...", text: $settings.anthropicAPIKey)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)

                                Button(action: { showingAnthropicKey.toggle() }) {
                                    Image(systemName: showingAnthropicKey ? "eye.slash" : "eye")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(.quaternary.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: TB.cornerXS, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if settings.provider == .anthropic && settings.anthropicAPIKey.isEmpty {
                            SettingsWarning(text: "Required for current provider")
                        }
                    }
                }

                // OpenAI Config
                SettingsSection(title: "OpenAI") {
                    VStack(alignment: .leading, spacing: TB.spacingSM) {
                        SettingsField(label: "Model") {
                            TextField("gpt-4o", text: $settings.openAIModel)
                                .textFieldStyle(.roundedBorder)
                        }

                        SettingsField(label: "API Key") {
                            HStack(spacing: TB.spacingXS) {
                                Group {
                                    if showingOpenAIKey {
                                        TextField("sk-...", text: $settings.openAIAPIKey)
                                    } else {
                                        SecureField("sk-...", text: $settings.openAIAPIKey)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)

                                Button(action: { showingOpenAIKey.toggle() }) {
                                    Image(systemName: showingOpenAIKey ? "eye.slash" : "eye")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(.quaternary.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: TB.cornerXS, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if settings.provider == .openai && settings.openAIAPIKey.isEmpty {
                            SettingsWarning(text: "Required for current provider")
                        }
                    }
                }

                // Security note
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 11))
                    Text("API keys are stored securely in your macOS Keychain.")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.tertiary)

                // Hotkey
                SettingsSection(title: "Hotkey") {
                    HStack {
                        Text("Activate TextBoost")
                            .font(.system(size: 13))
                        Spacer()
                        HotkeyRecorderView()
                    }
                }
            }
            .padding(TB.spacingLG)
        }
    }
}

// MARK: - Settings Components

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: TB.spacingSM) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            content
                .padding(TB.spacingMD)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: TB.cornerMD, style: .continuous)
                        .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

private struct SettingsField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            content
        }
    }
}

private struct SettingsWarning: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.orange)
    }
}
