import Foundation

struct Prompt: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String
    var shortDescription: String
    var systemPrompt: String

    init(id: UUID = UUID(), name: String, icon: String, shortDescription: String, systemPrompt: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.shortDescription = shortDescription
        self.systemPrompt = systemPrompt
    }

    static let builtInDefaults: [Prompt] = [
        Prompt(
            name: "Improve Email",
            icon: "envelope",
            shortDescription: "Polish tone & clarity",
            systemPrompt: "You are a writing assistant. Rewrite the following email to be clearer, more professional, and well-structured. Maintain the original intent and key information. Return only the rewritten email, no explanations."
        ),
        Prompt(
            name: "Rewrite 3S (Short, Simple, Strong)",
            icon: "text.line.first.and.arrowtriangle.forward",
            shortDescription: "Shorter, simpler, stronger",
            systemPrompt: "Rewrite the following text to be shorter, simpler, and stronger. Cut unnecessary words, use plain language, and make every sentence impactful. Return only the rewritten text, no explanations."
        ),
        Prompt(
            name: "TL;DR",
            icon: "text.badge.minus",
            shortDescription: "Summarize in 1-2 sentences",
            systemPrompt: "Summarize the following text in 1-2 concise sentences that capture the key point. Return only the summary, no explanations."
        ),
        Prompt(
            name: "Fix Grammar",
            icon: "checkmark.circle",
            shortDescription: "Fix errors, keep voice",
            systemPrompt: "Fix all grammar, spelling, and punctuation errors in the following text. Keep the original voice and tone. Return only the corrected text, no explanations."
        ),
        Prompt(
            name: "Make Professional",
            icon: "briefcase",
            shortDescription: "Formal business tone",
            systemPrompt: "Rewrite the following text in a professional, formal business tone suitable for corporate communication. Return only the rewritten text, no explanations."
        ),
        Prompt(
            name: "Make Friendly",
            icon: "face.smiling",
            shortDescription: "Warm, casual tone",
            systemPrompt: "Rewrite the following text in a warm, friendly, and approachable tone. Keep it natural and conversational. Return only the rewritten text, no explanations."
        ),
        Prompt(
            name: "Expand",
            icon: "arrow.up.left.and.arrow.down.right",
            shortDescription: "Add detail & depth",
            systemPrompt: "Expand the following text with more detail, context, and depth while maintaining the original message. Return only the expanded text, no explanations."
        ),
        Prompt(
            name: "Bullet Points",
            icon: "list.bullet",
            shortDescription: "Convert to bullet list",
            systemPrompt: "Convert the following text into clear, concise bullet points. Return only the bullet points, no explanations."
        ),
    ]
}
