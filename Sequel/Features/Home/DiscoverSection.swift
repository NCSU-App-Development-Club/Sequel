import SwiftUI
import Kingfisher

struct DiscoverSection: View {
    let shows: [ShowPreview]
    let onTap: (ShowPreview) -> Void
    let onBookmark: (ShowPreview) -> Void
    let isBookmarked: (Int) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(shows) { show in
                        discoverCard(show)
                            .onTapGesture { onTap(show) }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Text("Discover")
                .font(.title3.bold())
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Card (landscape, consistent 180x100)

    private func discoverCard(_ show: ShowPreview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                // Landscape backdrop card
                Group {
                    if let backdropPath = show.backdropPath,
                       let url = APIConfig.backdropCardURL(backdropPath) {
                        KFImage(url)
                            .resizable()
                            .placeholder { ShimmerView() }
                            .aspectRatio(16/9, contentMode: .fill)
                    } else if let posterPath = show.posterPath,
                              let url = APIConfig.posterListURL(posterPath) {
                        KFImage(url)
                            .resizable()
                            .placeholder { ShimmerView() }
                            .aspectRatio(16/9, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "tv")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 180, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Title overlay at bottom
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: 180, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .offset(y: 25)

                VStack(alignment: .leading, spacing: 2) {
                    Text(show.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let network = show.networks.first {
                            Text(network)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        ForEach(show.genres.prefix(1), id: \.self) { genre in
                            Text(genre)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(8)
            }

            Text(show.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .frame(width: 180, alignment: .leading)

            HStack(spacing: 4) {
                if let network = show.networks.first {
                    Text(network)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(show.genres.prefix(1), id: \.self) { genre in
                    Text(genre)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, alignment: .leading)
        }
        .contextMenu {
            Button {
                onBookmark(show)
            } label: {
                Label(
                    isBookmarked(show.id) ? "Remove from Watchlist" : "Save to Watchlist",
                    systemImage: isBookmarked(show.id) ? "bookmark.slash" : "bookmark"
                )
            }
            Button {
                onTap(show)
            } label: {
                Label("Open", systemImage: "arrow.right.circle")
            }
            ShareLink(item: "Check out \(show.title) on ShowThread!") {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
