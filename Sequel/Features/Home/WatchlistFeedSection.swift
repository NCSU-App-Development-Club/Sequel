import SwiftUI
import Kingfisher

struct WatchlistFeedSection: View {
    let episodes: [WatchlistEpisodePreview]
    let onTapShow: (Int, MediaType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            if episodes.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(episodes) { episode in
                            watchlistCard(episode)
                                .onTapGesture {
                                    onTapShow(episode.showTmdbId, episode.mediaType)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Text("From Your Watchlist")
                .font(.title3.bold())
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Save shows to see discussions here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }

    // MARK: - Card (landscape, consistent size)

    private func watchlistCard(_ episode: WatchlistEpisodePreview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Poster as landscape card
                Group {
                    if let posterPath = episode.posterPath,
                       let url = APIConfig.posterListURL(posterPath) {
                        KFImage(url)
                            .resizable()
                            .placeholder { ShimmerView() }
                            .aspectRatio(16/9, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(Image(systemName: "film").foregroundStyle(.secondary))
                    }
                }
                .frame(width: 180, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // New episodes badge
                if episode.commentCount > 0 {
                    Text("\(episode.commentCount) new")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                }
            }

            Text(episode.showTitle)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .frame(width: 180, alignment: .leading)

            if let airDate = episode.airDate {
                Text("New episode \(airDate.relativeString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 180, alignment: .leading)
            }
        }
    }
}
