import SwiftUI
import Kingfisher

struct TrendingCarouselView: View {
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
                        trendingCard(show)
                            .onTapGesture { onTap(show) }
                    }
                }
                .padding(.horizontal, GlassTokens.Padding.horizontal)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("Trending Now")
                .font(.title3.bold())
        }
        .padding(.horizontal, GlassTokens.Padding.horizontal)
    }

    // MARK: - Card

    private func trendingCard(_ show: ShowPreview) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop image
            Group {
                if let backdropPath = show.backdropPath,
                   let url = APIConfig.backdropCardURL(backdropPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(16/9, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            Image(systemName: "tv")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 300, height: 170)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Text(show.title)
                    .font(.episodeTitle)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let year = show.yearString {
                        Text(year)
                            .font(.metadata)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    if let network = show.networks.first {
                        Text(network)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(12)

            // Bookmark button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onBookmark(show)
                    } label: {
                        Image(systemName: isBookmarked(show.id) ? "bookmark.fill" : "bookmark")
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(8)
                }
                Spacer()
            }
        }
        .frame(width: 300, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: GlassTokens.CornerRadius.showCard))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
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
