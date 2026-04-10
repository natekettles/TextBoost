import Foundation

final class OpenAIService {
    static let shared = OpenAIService()
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    func streamMessage(systemPrompt: String, userMessage: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: baseURL)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(SettingsManager.shared.openAIAPIKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "content-type")

                    let model = SettingsManager.shared.openAIModel
                    var body: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": userMessage]
                        ]
                    ]
                    // Newer OpenAI models (o1, gpt-5, etc.) require max_completion_tokens
                    // instead of max_tokens
                    if model.hasPrefix("o1") || model.hasPrefix("o3") || model.contains("gpt-5") {
                        body["max_completion_tokens"] = 4096
                    } else {
                        body["max_tokens"] = 4096
                    }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        continuation.finish(throwing: APIError.httpError(
                            statusCode: httpResponse.statusCode,
                            message: errorBody
                        ))
                        return
                    }

                    for try await line in bytes.lines {
                        try Task.checkCancellation()

                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        guard jsonString != "[DONE]",
                              let data = jsonString.data(using: .utf8) else { continue }

                        if let chunk = try? JSONDecoder().decode(OpenAIChatChunk.self, from: data),
                           let text = chunk.choices.first?.delta.content {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

// MARK: - OpenAI SSE Models

private struct OpenAIChatChunk: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }
}
