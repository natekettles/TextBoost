import Foundation
import SwiftUI

enum AIProvider: String, CaseIterable, Identifiable {
    case anthropic = "anthropic"
    case openai = "openai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        }
    }
}

private enum KeychainKeys {
    static let anthropicAPIKey = "anthropic_api_key"
    static let openAIAPIKey = "openai_api_key"
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("ai_provider") var provider: AIProvider = .anthropic
    @AppStorage("anthropic_model") var anthropicModel: String = "claude-sonnet-4-20250514"
    @AppStorage("openai_model") var openAIModel: String = "gpt-4o"

    var activeModel: String {
        switch provider {
        case .anthropic: return anthropicModel
        case .openai: return openAIModel
        }
    }

    @Published var anthropicAPIKey: String {
        didSet { KeychainHelper.save(key: KeychainKeys.anthropicAPIKey, value: anthropicAPIKey) }
    }

    @Published var openAIAPIKey: String {
        didSet { KeychainHelper.save(key: KeychainKeys.openAIAPIKey, value: openAIAPIKey) }
    }

    var activeAPIKey: String {
        switch provider {
        case .anthropic: return anthropicAPIKey
        case .openai: return openAIAPIKey
        }
    }

    private init() {
        // Load keys from Keychain on startup
        self.anthropicAPIKey = KeychainHelper.load(key: KeychainKeys.anthropicAPIKey)
        self.openAIAPIKey = KeychainHelper.load(key: KeychainKeys.openAIAPIKey)

        // Migrate from UserDefaults if keys exist there (one-time migration)
        migrateFromUserDefaults()
    }

    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        if let oldAnthropicKey = defaults.string(forKey: "anthropic_api_key"), !oldAnthropicKey.isEmpty, anthropicAPIKey.isEmpty {
            anthropicAPIKey = oldAnthropicKey
            defaults.removeObject(forKey: "anthropic_api_key")
        }
        if let oldOpenAIKey = defaults.string(forKey: "openai_api_key"), !oldOpenAIKey.isEmpty, openAIAPIKey.isEmpty {
            openAIAPIKey = oldOpenAIKey
            defaults.removeObject(forKey: "openai_api_key")
        }
    }
}

extension AIProvider: RawRepresentable {}
