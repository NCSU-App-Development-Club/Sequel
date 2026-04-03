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
                    }
                }
                .frame(width: 180, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Comment count overlay
                if show.voteAverage > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.right")
                            .font(.caption2)
                        Text("\(Int(show.voteAverage * 10))")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                    .padding(6)
                }
            }

            Text(show.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .frame(width: 180, alignment: .leading)

            HStack(spacing: 4) {
                if let year = show.yearString {
                    Text(year)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let network = show.networks.first {
                    Text(network)
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
