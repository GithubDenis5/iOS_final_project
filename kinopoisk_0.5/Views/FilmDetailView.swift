import SwiftUI

struct FilmDetailView: View {
    let id: Int
    @State private var film: FilmDetail?
    @State private var isLoading = true
    @State private var error: String?
    @EnvironmentObject var favorites: FavoritesManager
    @EnvironmentObject var watched: WatchedManager
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding()
            } else if let film {
                VStack(alignment: .leading, spacing: 12) {
                    GeometryReader { geometry in
                        AsyncImage(url: film.backdropURL) { phase in
                            if let img = phase.image {
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 200)
                                    .clipped()
                            } else if phase.error != nil {
                                Color.gray
                                    .frame(width: geometry.size.width, height: 200)
                            } else {
                                Color.gray
                                    .frame(width: geometry.size.width, height: 200)
                                    .overlay(ProgressView())
                            }
                        }
                        .frame(width: geometry.size.width, height: 200)
                    }
                    .frame(height: 200)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(film.title).font(.largeTitle).bold()
                        if let tagline = film.tagline, !tagline.isEmpty {
                            Text(tagline).italic().font(.subheadline)
                        }
                        HStack {
                            Label(film.ratingText, systemImage: "star.fill").font(.caption)
                            Text(film.year).font(.caption)
                            Text(film.runtimeText).font(.caption)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(film.genres, id: \.id) { genre in
                                    Text(genre.name).font(.caption2).padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                                }
                            }
                        }
                        Divider()
                        Text("О фильме").font(.headline)
                        Text(film.overview).font(.body)
                        
                        HStack {
                            Button {
                                favorites.toggle(film: film)
                            } label: {
                                Label(favorites.isFavorite(film.id) ? "В избранном" : "В избранное",
                                      systemImage: favorites.isFavorite(film.id) ? "heart.fill" : "heart")
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                watched.toggle(film: film)
                            } label: {
                                Label(watched.isWatched(film.id) ? "Просмотрено" : "Просмотреть",
                                      systemImage: watched.isWatched(film.id) ? "eye.fill" : "eye")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal, 16)
                }
            } else if let error {
                Text("Ошибка: \(error)")
            }
        }
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }
    
    private func load() async {
        isLoading = true
        error = nil
        do {
            film = try await NetworkService().detail(id: id)
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }
}
