import Foundation

final class AnthropicService {
    static let shared = AnthropicService()
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    func streamMessage(systemPrompt: String, userMessage: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: baseURL)
                    request.httpMethod = "POST"
                    request.setValue(SettingsManager.shared.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2025-04-14", forHTTPHeaderField: "anthropic-version")
                    request.setValue("application/json", forHTTPHeaderField: "content-type")

                    let body: [String: Any] = [
                        "model": SettingsManager.shared.anthropicModel,
                        "max_tokens": 4096,
                        "stream": true,
                        "system": systemPrompt,
                        "messages": [
                            ["role": "user", "content": userMessage]
                        ]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        // Try to read error body
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

                        if let event = try? JSONDecoder().decode(StreamEvent.self, from: data),
                           event.type == "content_block_delta",
                           let text = event.delta?.text {
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

// MARK: - SSE Event Models

private struct StreamEvent: Decodable {
    let type: String
    let delta: Delta?
}

private struct Delta: Decodable {
    let text: String?
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from API."
        case .httpError(let code, let message):
            return "API error (\(code)): \(message)"
        }
    }
}
