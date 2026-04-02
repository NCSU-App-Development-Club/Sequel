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
                ForEach(episodes) { episode in
                    watchlistRow(episode)
                        .onTapGesture {
                            onTapShow(episode.showTmdbId, episode.mediaType)
                        }
                }
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(AppColors.accent)
            Text("From Your Watchlist")
                .font(.title3.bold())
        }
        .padding(.horizontal, GlassTokens.Padding.horizontal)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Save shows to see discussions here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, GlassTokens.Padding.horizontal)
    }

    // MARK: - Row

    private func watchlistRow(_ episode: WatchlistEpisodePreview) -> some View {
        HStack(spacing: 12) {
            // Poster thumbnail
            Group {
                if let posterPath = episode.posterPath,
                   let url = APIConfig.posterListURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(2/3, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(Image(systemName: "film").foregroundStyle(.secondary))
                }
            }
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.showTitle)
                    .font(.episodeTitle)
                    .lineLimit(1)

                Text("\(episode.episodeLabel) · \(episode.episodeName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let airDate = episode.airDate {
                    Text(airDate.relativeString)
                        .font(.metadata)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }

            Spacer(minLength: 0)

            // Unread indicator
            Circle()
                .fill(AppColors.accent)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, GlassTokens.Padding.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
