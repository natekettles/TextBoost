import Foundation
import os.log

private let log = Logger(subsystem: "com.nathanskidmore.TextBoost", category: "PromptStore")

final class PromptStore: ObservableObject {
    static let shared = PromptStore()

    @Published var prompts: [Prompt] {
        didSet { save() }
    }

    private static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("TextBoost", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("prompts.json")
    }

    private init() {
        if let loaded = Self.load() {
            self.prompts = loaded
        } else {
            self.prompts = Prompt.builtInDefaults
        }
    }

    func search(_ query: String) -> [Prompt] {
        if query.isEmpty { return prompts }
        return prompts.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.shortDescription.localizedCaseInsensitiveContains(query)
        }
    }

    func add(_ prompt: Prompt) {
        prompts.append(prompt)
    }

    func update(_ prompt: Prompt) {
        guard let index = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        prompts[index] = prompt
    }

    func delete(at offsets: IndexSet) {
        prompts.remove(atOffsets: offsets)
    }

    func delete(id: UUID) {
        prompts.removeAll { $0.id == id }
    }

    func move(from source: IndexSet, to destination: Int) {
        prompts.move(fromOffsets: source, toOffset: destination)
    }

    func resetToDefaults() {
        prompts = Prompt.builtInDefaults
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(prompts)
            try data.write(to: Self.storageURL, options: .atomic)
        } catch {
            log.error("Failed to save prompts: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func load() -> [Prompt]? {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: storageURL)
            return try JSONDecoder().decode([Prompt].self, from: data)
        } catch {
            log.error("Failed to load prompts: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
