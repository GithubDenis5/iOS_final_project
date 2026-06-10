import Foundation
import SwiftUI
import Combine

@MainActor
final class RecommendationBot: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading = false
    @Published var mode: Mode = .dialog
    @Published var films: [Film] = []
    @Published var availableModels: [String] = []
    @Published var selectedModel: String = ""
    @Published var isLoadingModels = false
    @Published var waitingForDelay = false
    
    @AppStorage("openRouterApiKey") var apiKey: String = ""
    
    enum Mode { case dialog, finished }
    
    private let systemPrompt = """
    Ты кино-рекомендательный ассистент.
    Правила:
    - Не используй markdown, эмодзи, списки с пометками. Только обычный текст.
    - Задай максимум 3 вопроса (включая приветствие). На четвёртом твоём сообщении обязательно выдай список фильмов в формате:
      FILMS:
      - Название фильма 1
      - Название фильма 2
      ...
    - Будь краток, не задавай лишних уточнений.
    Сейчас начни диалог: поприветствуй пользователя и задай первый вопрос (например, о любимых жанрах).
    """
    
    private var conversationHistory: [[String: String]] = []
    private let networkService = NetworkService()
    private var delayTask: Task<Void, Never>?
    
    init() {
        if !apiKey.isEmpty {
            Task {
                await loadModels()
                await sendSystemPrompt()
            }
        } else {
            messages.append(Message(content: "Введите API-ключ OpenRouter в настройках профиля, чтобы начать общение.", isUser: false))
        }
    }
    
    func loadModels() async {
        guard !apiKey.isEmpty else { return }
        isLoadingModels = true
        do {
            let service = BotAPIService(apiKey: apiKey)
            let models = try await service.fetchFreeTextModels()
            availableModels = models
            if let first = models.first, selectedModel.isEmpty {
                selectedModel = first
            }
        } catch {
            print("Ошибка загрузки моделей: \(error)")
        }
        isLoadingModels = false
    }
    
    private func sendSystemPrompt() async {
        guard !apiKey.isEmpty, !selectedModel.isEmpty else { return }
        isLoading = true
        
        let service = BotAPIService(apiKey: apiKey)
        let requestMessages = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": systemPrompt]
        ]
        
        do {
            let response = try await service.sendMessage(messages: requestMessages, model: selectedModel)
            conversationHistory.append(["role": "assistant", "content": response])
            messages.append(Message(content: response, isUser: false))
            mode = .dialog
        } catch {
            messages.append(Message(content: "Ошибка: \(error.localizedDescription)", isUser: false))
        }
        isLoading = false
    }
    
    func sendMessage() async {
        guard !apiKey.isEmpty else {
            messages.append(Message(content: "Сначала добавьте API-ключ OpenRouter в профиле.", isUser: false))
            return
        }
        
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        
        let userMsg = Message(content: text, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isLoading = true
        waitingForDelay = true
        
        conversationHistory.append(["role": "user", "content": text])
        
        var apiMessages = [[String: String]]()
        apiMessages.append(["role": "system", "content": systemPrompt])
        apiMessages.append(contentsOf: conversationHistory)
        
        delayTask?.cancel()
        delayTask = Task {
            try? await Task.sleep(nanoseconds: 45_000_000_000)
        }
        await delayTask?.value
        waitingForDelay = false
        
        if Task.isCancelled {
            isLoading = false
            return
        }
        
        let service = BotAPIService(apiKey: apiKey)
        
        do {
            let response = try await service.sendMessage(messages: apiMessages, model: selectedModel)
            conversationHistory.append(["role": "assistant", "content": response])
            
            if let filmsList = await extractFilms(from: response) {
                mode = .finished
                films = filmsList
            } else {
                messages.append(Message(content: response, isUser: false))
                mode = .dialog
            }
        } catch {
            messages.append(Message(content: "Ошибка: \(error.localizedDescription)", isUser: false))
        }
        
        isLoading = false
    }
    
    private func extractFilms(from text: String) async -> [Film]? {
        guard text.contains("FILMS:") else { return nil }
        let lines = text.components(separatedBy: .newlines)
        let titles = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("-") else { return nil }
            return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        guard !titles.isEmpty else { return nil }
        
        var realFilms: [Film] = []
        for title in titles {
            do {
                let searchResults = try await networkService.search(query: title)
                if let firstMatch = searchResults.first {
                    realFilms.append(firstMatch)
                }
            } catch {
                print("Ошибка поиска для '\(title)': \(error)")
            }
        }
        return realFilms.isEmpty ? nil : realFilms
    }
    
    func clearChat() {
        delayTask?.cancel()
        messages.removeAll()
        films.removeAll()
        mode = .dialog
        conversationHistory.removeAll()
        if !apiKey.isEmpty {
            Task { await sendSystemPrompt() }
        } else {
            messages.append(Message(content: "Введите API-ключ OpenRouter в настройках профиля, чтобы начать общение.", isUser: false))
        }
    }
    
    func reset() {
        clearChat()
    }
}
