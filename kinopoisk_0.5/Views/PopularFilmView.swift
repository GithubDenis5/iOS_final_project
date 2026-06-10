import SwiftUI

struct PopularFilmView: View {
    @State private var films: [Film] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var currentPage = 1
    @State private var canLoadMore = true
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(films) { film in
                    NavigationLink(destination: FilmDetailView(id: film.id)) {
                        FilmCard(film: film)
                    }
                    .listRowSeparator(.hidden)
                    .onAppear {
                        if film.id == films.last?.id && canLoadMore {
                            Task { await loadMore() }
                        }
                    }
                }
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable { await refresh() }
            .overlay {
                if films.isEmpty && error == nil && !isLoading {
                    ProgressView()
                } else if let error = error, films.isEmpty {
                    VStack {
                        Text("Ошибка")
                        Text(error).font(.caption)
                        Button("Повторить") { Task { await loadFirstPage() } }
                    }
                }
            }
            .navigationTitle("Популярные")
        }
        .task { await loadFirstPage() }
    }
    
    private func loadFirstPage() async {
        currentPage = 1
        canLoadMore = true
        films = []
        await loadMore()
    }
    
    private func loadMore() async {
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        error = nil
        do {
            let newFilms = try await NetworkService().popular(page: currentPage)
            if newFilms.isEmpty {
                canLoadMore = false
            } else {
                films.append(contentsOf: newFilms)
                currentPage += 1
            }
        } catch let err {
            error = err.localizedDescription
        }
        isLoading = false
    }
    
    private func refresh() async {
        await loadFirstPage()
    }
}
