import Foundation

class NetworkService {
    private let base = "https://api.themoviedb.org/3"
    
    private func request(_ url: URL) throws -> URLRequest {
        guard let token = AuthManager.shared.getToken() else {
            throw NetworkError.noToken
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return req
    }
    
    func popular(page: Int = 1) async throws -> [Film] {
        let url = URL(string: "\(base)/movie/popular?page=\(page)")!
        let (data, _) = try await URLSession.shared.data(for: request(url))
        let res = try JSONDecoder().decode(PopularResponse.self, from: data)
        return res.results
    }
    
    func search(query: String) async throws -> [Film] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "\(base)/search/movie?query=\(encoded)")!
        let (data, _) = try await URLSession.shared.data(for: request(url))
        let res = try JSONDecoder().decode(SearchResponse.self, from: data)
        return res.results
    }
    
    func detail(id: Int) async throws -> FilmDetail {
        let url = URL(string: "\(base)/movie/\(id)")!
        let (data, _) = try await URLSession.shared.data(for: request(url))
        return try JSONDecoder().decode(FilmDetail.self, from: data)
    }
    
    func genres() async throws -> [Genre] {
        let url = URL(string: "\(base)/genre/movie/list")!

        let (data, _) = try await URLSession.shared.data(
            for: request(url)
        )

        let response = try JSONDecoder().decode(
            GenresResponse.self,
            from: data
        )

        return response.genres
    }
    
    func discoverMovies(
        genreId: Int? = nil,
        year: Int? = nil,
        minRating: Double = 6.5,
        page: Int = 1
    ) async throws -> [Film] {

        var components = URLComponents(
            string: "\(base)/discover/movie"
        )!

        var queryItems: [URLQueryItem] = [
            .init(name: "sort_by", value: "vote_average.desc"),
            .init(name: "vote_count.gte", value: "500"),
            .init(name: "vote_average.gte", value: "\(minRating)"),
            .init(name: "page", value: "\(page)")
        ]

        if let genreId {
            queryItems.append(
                .init(
                    name: "with_genres",
                    value: "\(genreId)"
                )
            )
        }

        if let year {
            queryItems.append(
                .init(
                    name: "primary_release_year",
                    value: "\(year)"
                )
            )
        }

        components.queryItems = queryItems

        let url = components.url!

        let (data, _) = try await URLSession.shared.data(
            for: request(url)
        )

        let response = try JSONDecoder().decode(
            SearchResponse.self,
            from: data
        )

        return response.results
    }
    
    func genreId(for genreName: String) async throws -> Int? {

        let genres = try await genres()

        return genres.first {
            $0.name.lowercased()
                .contains(
                    genreName.lowercased()
                )
        }?.id
    }
}

enum NetworkError: Error {
    case noToken
}

struct GenresResponse: Codable {
    let genres: [Genre]
}

struct PopularResponse: Codable { let results: [Film] }
struct SearchResponse: Codable { let results: [Film] }
