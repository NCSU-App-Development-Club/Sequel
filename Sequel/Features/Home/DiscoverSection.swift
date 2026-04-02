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
                LazyHStack(spacing: 14) {
                    ForEach(shows) { show in
                        discoverCard(show)
                            .onTapGesture { onTap(show) }
                    }
                }
                .padding(.horizontal, GlassTokens.Padding.horizontal)
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
            Text("Discover")
                .font(.title3.bold())
        }
        .padding(.horizontal, GlassTokens.Padding.horizontal)
    }

    // MARK: - Card

    private func discoverCard(_ show: ShowPreview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster
            ZStack(alignment: .topTrailing) {
                Group {
                    if let posterPath = show.posterPath,
                       let url = APIConfig.posterListURL(posterPath) {
                        KFImage(url)
                            .resizable()
                            .placeholder { ShimmerView() }
                            .aspectRatio(2/3, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .aspectRatio(2/3, contentMode: .fill)
                            .overlay(
                                Image(systemName: "tv")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 130, height: 195)
                .clipShape(RoundedRectangle(cornerRadius: GlassTokens.CornerRadius.showCard))

                // Bookmark button
                Button {
                    onBookmark(show)
                } label: {
                    Image(systemName: isBookmarked(show.id) ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(6)
            }

            // Title
            Text(show.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .frame(width: 130, alignment: .leading)

            // Genre tags
            if !show.genres.isEmpty {
                HStack(spacing: 4) {
                    ForEach(show.genres.prefix(2), id: \.self) { genre in
                        Text(genre)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5), in: Capsule())
                    }
                }
            }
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
