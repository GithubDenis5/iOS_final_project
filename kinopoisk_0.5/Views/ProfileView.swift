import SwiftUI

struct ProfileView: View {
    @AppStorage("username") var username = "Гость"
    @AppStorage("openRouterApiKey") var apiKey = ""
    @EnvironmentObject var favorites: FavoritesManager
    @EnvironmentObject var watched: WatchedManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("Аккаунт") {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title)
                        TextField("Имя", text: $username)
                    }
                    Button("Сменить токен") {
                        authManager.logout()
                    }
                    .foregroundColor(.red)
                }
                
                Section("OpenRouter API") {
                    if !apiKey.isEmpty {
                        HStack {
                            Text("API ключ: ••••••••")
                            Spacer()
                            Button("Удалить") {
                                apiKey = ""
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Text("API ключ не задан")
                            .foregroundColor(.secondary)
                    }
                    Text("Получить ключ можно на openrouter.ai")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Мои фильмы") {
                    NavigationLink("Избранное (\(favorites.favoriteFilms.count))") {
                        FilmList(films: favorites.favoriteFilms, title: "Избранное")
                    }
                    NavigationLink("Просмотренные (\(watched.watchedFilms.count))") {
                        FilmList(films: watched.watchedFilms, title: "Просмотренные")
                    }
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

struct FilmList: View {
    let films: [FilmDetail]
    let title: String
    
    var body: some View {
        List(films) { film in
            NavigationLink(destination: FilmDetailView(id: film.id)) {
                HStack {
                    AsyncImage(url: film.posterURL) { phase in
                        if let img = phase.image {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.gray
                        }
                    }
                    .frame(width: 40, height: 60)
                    .cornerRadius(4)
                    Text(film.title).font(.headline)
                    Spacer()
                }
            }
        }
        .navigationTitle(title)
    }
}
