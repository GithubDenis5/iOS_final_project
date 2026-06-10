import Foundation

struct BotAPIService {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchFreeTextModels() async throws -> [String] {
        let url = URL(string: "\(baseURL)/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
        
        let freeTextModels = response.data.filter { model in
            let isText = model.architecture.output_modalities.contains("text")
            let isFree = model.pricing.prompt == "0" && model.pricing.completion == "0"
            return isText && isFree
        }
        return freeTextModels.map { $0.id }.sorted()
    }
    
    func sendMessage(messages: [[String: String]], model: String) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/your-app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("Kinopoisk Recommender", forHTTPHeaderField: "X-OpenRouter-Title")
        
        let payload: [String: Any] = [
            "model": model,
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let errorResponse = try? JSONDecoder().decode(OpenRouterErrorResponse.self, from: data) {
            throw NSError(domain: "OpenRouter", code: 1, userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message])
        }
        
        let response = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }
}

struct ModelsResponse: Decodable {
    let data: [ModelInfo]
}

struct ModelInfo: Decodable {
    let id: String
    let architecture: ArchitectureInfo
    let pricing: PricingInfo
}

struct ArchitectureInfo: Decodable {
    let output_modalities: [String]
}

struct PricingInfo: Decodable {
    let prompt: String
    let completion: String
}

struct OpenRouterResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: MessageContent
}

struct MessageContent: Decodable {
    let content: String
}

struct OpenRouterErrorResponse: Decodable {
    let error: ErrorDetail
}

struct ErrorDetail: Decodable {
    let message: String
}
