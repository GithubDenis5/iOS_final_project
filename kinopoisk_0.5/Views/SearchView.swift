import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [Film] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            List(results) { film in
                NavigationLink(destination: FilmDetailView(id: film.id)) {
                    FilmCard(film: film)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Название фильма")
            .onSubmit(of: .search) { Task { await search() } }
            .overlay {
                if isSearching { ProgressView() }
                else if results.isEmpty && !query.isEmpty { Text("Ничего не найдено") }
            }
            .navigationTitle("Поиск")
        }
    }
    
    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        do {
            results = try await NetworkService().search(query: query)
        } catch {
            results = []
        }
        isSearching = false
    }
}
