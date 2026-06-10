import SwiftUI

struct FilmCard: View {
    let film: Film
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: film.posterURL) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray
                }
            }
            .frame(width: 60, height: 90)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(film.title).font(.headline).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", film.voteAverage))
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("(\(film.voteCount))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(film.year).font(.caption).foregroundColor(.secondary)
                Text(film.overview).font(.caption).lineLimit(2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
