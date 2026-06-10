import SwiftUI

@main
struct ios_final_projectApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var favorites = FavoritesManager()
    @StateObject private var watched = WatchedManager()
    @StateObject private var recommendationBot = RecommendationBot()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView(recommendationBot: recommendationBot)
                    .environmentObject(favorites)
                    .environmentObject(watched)
                    .environmentObject(authManager)
            } else {
                TokenInputView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct ContentView: View {
    let recommendationBot: RecommendationBot
    
    var body: some View {
        TabView {
            PopularFilmView()
                .tabItem {
                    Label("Главная", systemImage: "house")
                }
            SearchView()
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            RecommendationsView(bot: recommendationBot)
                .tabItem {
                    Label("Рекомендации", systemImage: "sparkles")
                }
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
    }
}
