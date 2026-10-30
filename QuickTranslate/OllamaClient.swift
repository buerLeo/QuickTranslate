import Foundation

final class OllamaClient {
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/generate")!
    private let model = "qwen3:4b-instruct"

    private struct Request: Encodable {
        let model: String
        let prompt: String
        let stream: Bool
        let think: Bool
        let keep_alive: String
        let options: Options

        struct Options: Encodable {
            let num_ctx: Int
            let temperature: Double
        }
    }

    private struct Response: Decodable {
        let response: String?
        let error: String?
    }

    func translate(_ text: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Request(
            model: model,
            prompt: "Translate the following text into Simplified Chinese. Return only the translation, without explanations, notes, or surrounding quotation marks. Preserve names, numbers, formatting, and line breaks when possible.\n\n\(text)",
            stream: false,
            think: false,
            keep_alive: "5m",
            options: .init(num_ctx: 2048, temperature: 0.2)
        ))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw QuickTranslateError.ollamaUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw QuickTranslateError.invalidResponse
        }
        if http.statusCode == 404 { throw QuickTranslateError.modelMissing }
        guard (200..<300).contains(http.statusCode) else {
            throw QuickTranslateError.requestFailed("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        if let error = decoded.error, !error.isEmpty {
            if error.localizedCaseInsensitiveContains("not found") {
                throw QuickTranslateError.modelMissing
            }
            throw QuickTranslateError.requestFailed(error)
        }
        guard let answer = decoded.response?.trimmingCharacters(in: .whitespacesAndNewlines), !answer.isEmpty else {
            throw QuickTranslateError.invalidResponse
        }
        return answer
    }
}
