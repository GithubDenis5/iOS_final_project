import SwiftUI

struct RecommendationsView: View {
    @StateObject var bot: RecommendationBot
    @State private var tempApiKey = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                if bot.apiKey.isEmpty {
                    apiKeyInputView
                } else {
                    if bot.availableModels.isEmpty && !bot.isLoadingModels {
                        Text("Загрузка моделей...")
                            .padding()
                    } else {
                        chatView

                        if bot.mode != .finished {
                            inputArea
                        } else {
                            newSearchButton
                        }
                    }
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .onAppear {
                if !bot.apiKey.isEmpty && bot.availableModels.isEmpty {
                    Task { await bot.loadModels() }
                }
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            Text("Кино-ассистент")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if bot.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }

            if !bot.apiKey.isEmpty {
                Menu {
                    Picker("Модель", selection: $bot.selectedModel) {
                        ForEach(bot.availableModels, id: \.self) { model in
                            Text(model.components(separatedBy: "/").last ?? model)
                                .tag(model)
                        }
                    }
                    .onChange(of: bot.selectedModel) { _ in
                        Task { await bot.clearChat() }
                    }
                } label: {
                    Image(systemName: "cpu")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                }

                Button {
                    Task { await bot.clearChat() }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var apiKeyInputView: some View {
        VStack(spacing: 20) {
            Text("Для работы рекомендаций нужен API-ключ OpenRouter")
                .multilineTextAlignment(.center)
                .padding()

            SecureField("Введите API-ключ", text: $tempApiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button("Сохранить") {
                bot.apiKey = tempApiKey
                tempApiKey = ""
                Task {
                    await bot.loadModels()
                    await bot.clearChat()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(tempApiKey.isEmpty)

            Spacer()
        }
        .padding()
    }

    private var chatView: some View {
        let hasUserMessages = bot.messages.contains(where: { $0.isUser })

        return ZStack {
            if !hasUserMessages {
                VStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 32))
                    Text("Модель можно выбрать")
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text("через кнопку")
                        Image(systemName: "cpu")
                    }
                    .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(bot.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }

                        if bot.mode == .finished && !bot.films.isEmpty {
                            recommendationsSection
                        }

                        if bot.waitingForDelay {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    ProgressView()
                                    Text("Ожидание 45 сек...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: bot.messages.count) { _ in
                    withAnimation {
                        if let last = bot.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎬 Рекомендуемые фильмы")
                .font(.headline)
                .padding(.top, 8)

            ForEach(bot.films) { film in
                NavigationLink(destination: FilmDetailView(id: film.id)) {
                    FilmCard(film: film)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Сообщение...", text: $bot.inputText)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .disabled(bot.isLoading)

            Button {
                Task { await bot.sendMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        (bot.isLoading || bot.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        ? Color.gray
                        : Color.blue
                    )
                    .clipShape(Circle())
            }
            .disabled(bot.isLoading || bot.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var newSearchButton: some View {
        Button {
            bot.reset()
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Новый поиск")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(28)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            } else {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(.top, 6)
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 4)
    }
}
