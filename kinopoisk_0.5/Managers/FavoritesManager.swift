import Foundation
import SwiftUI
import Combine

class FavoritesManager: ObservableObject {
    @Published var favoriteFilms: [FilmDetail] = []
    
    private let key = "favoriteFilms"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FilmDetail].self, from: data) {
            favoriteFilms = decoded
        }
    }
    
    func isFavorite(_ id: Int) -> Bool {
        favoriteFilms.contains { $0.id == id }
    }
    
    func toggle(film: FilmDetail) {
        if isFavorite(film.id) {
            favoriteFilms.removeAll { $0.id == film.id }
        } else {
            favoriteFilms.append(film)
        }
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(favoriteFilms) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
