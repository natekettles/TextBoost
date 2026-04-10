import Foundation
import AppKit

@MainActor
final class ConversationState: ObservableObject {
    @Published var inputText: String = ""
    @Published var responseText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPrompt: Prompt?

    private let textCaptureService: TextCaptureService
    private var currentTask: Task<Void, Never>?

    init(textCaptureService: TextCaptureService) {
        self.textCaptureService = textCaptureService
    }

    func reset() {
        inputText = ""
        responseText = ""
        isProcessing = false
        errorMessage = nil
        selectedPrompt = nil
        currentTask?.cancel()
    }

    func clearResponse() {
        responseText = ""
        isProcessing = false
        errorMessage = nil
        selectedPrompt = nil
    }

    func executePrompt(_ prompt: Prompt) {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No input text provided."
            return
        }

        let settings = SettingsManager.shared
        guard !settings.activeAPIKey.isEmpty else {
            errorMessage = "No API key set. Open Settings to add your \(settings.provider.displayName) API key."
            return
        }

        selectedPrompt = prompt
        isProcessing = true
        responseText = ""
        errorMessage = nil

        currentTask = Task {
            do {
                let stream: AsyncThrowingStream<String, Error>
                switch settings.provider {
                case .anthropic:
                    stream = AnthropicService.shared.streamMessage(
                        systemPrompt: prompt.systemPrompt,
                        userMessage: inputText
                    )
                case .openai:
                    stream = OpenAIService.shared.streamMessage(
                        systemPrompt: prompt.systemPrompt,
                        userMessage: inputText
                    )
                }
                for try await chunk in stream {
                    responseText += chunk
                }
                isProcessing = false
            } catch is CancellationError {
                // Cancelled — do nothing
            } catch {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }

    func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(responseText, forType: .string)
    }

    func insertResponse(onDismiss: () -> Void) {
        let text = responseText
        let previousApp = textCaptureService.previousApp
        onDismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PasteService().pasteText(text, into: previousApp)
        }
    }
}
