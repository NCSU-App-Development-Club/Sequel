import SwiftUI
import Kingfisher

struct RecentlyAiredSection: View {
    let shows: [ShowPreview]
    let onTap: (ShowPreview) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            ForEach(shows) { show in
                recentRow(show)
                    .onTapGesture { onTap(show) }
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundStyle(.green)
            Text("Recently Aired")
                .font(.title3.bold())
        }
        .padding(.horizontal, GlassTokens.Padding.horizontal)
    }

    // MARK: - Row

    private func recentRow(_ show: ShowPreview) -> some View {
        HStack(spacing: 12) {
            // Poster
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
                        .overlay(Image(systemName: "film").foregroundStyle(.secondary))
                }
            }
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.episodeTitle)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let year = show.yearString {
                        Text(year)
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }
                    if let network = show.networks.first {
                        Text(network)
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }
                }

                if show.voteAverage > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", show.voteAverage))
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, GlassTokens.Padding.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
