import Foundation
import SwiftUI
import Combine

class WatchedManager: ObservableObject {
    @Published var watchedFilms: [FilmDetail] = []
    
    private let key = "watchedFilms"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FilmDetail].self, from: data) {
            watchedFilms = decoded
        }
    }
    
    func isWatched(_ id: Int) -> Bool {
        watchedFilms.contains { $0.id == id }
    }
    
    func toggle(film: FilmDetail) {
        if isWatched(film.id) {
            watchedFilms.removeAll { $0.id == film.id }
        } else {
            watchedFilms.append(film)
        }
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(watchedFilms) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
