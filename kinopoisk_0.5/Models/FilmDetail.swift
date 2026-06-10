import Foundation

struct FilmDetail: Identifiable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String
    let voteAverage: Double
    let genres: [Genre]
    let runtime: Int?
    let tagline: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, overview, genres, runtime, tagline
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w300\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }
    
    var year: String { String(releaseDate.prefix(4)) }
    var ratingText: String { String(format: "%.1f", voteAverage) }
    var runtimeText: String { runtime != nil ? "\(runtime!) мин" : "—" }
}

struct Genre: Codable {
    let id: Int
    let name: String
}
