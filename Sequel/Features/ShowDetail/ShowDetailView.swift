import SwiftUI
import SwiftData
import Kingfisher

struct ShowDetailView: View {
    let tmdbId: Int
    let mediaType: MediaType

    @State private var viewModel = ShowDetailViewModel()
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    init(tmdbId: Int, mediaType: MediaType = .tvShow) {
        self.tmdbId = tmdbId
        self.mediaType = mediaType
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.show == nil {
                loadingView
            } else if let show = viewModel.show {
                showContent(show)
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadShow(tmdbId: tmdbId, mediaType: mediaType, context: modelContext)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero shimmer
                ShimmerView()
                    .frame(height: 220)

                VStack(alignment: .leading, spacing: 16) {
                    ShimmerView().frame(height: 28).clipShape(RoundedRectangle(cornerRadius: 4))
                    ShimmerView().frame(width: 200, height: 16).clipShape(RoundedRectangle(cornerRadius: 4))
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerView().frame(width: 60, height: 28).clipShape(Capsule())
                        }
                    }
                }
                .padding(GlassTokens.Padding.horizontal)
            }
        }
    }

    // MARK: - Show Content

    private func showContent(_ show: Show) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Hero Backdrop
                heroSection(show)

                VStack(alignment: .leading, spacing: 20) {
                    // Stale banner
                    if viewModel.isStale {
                        staleBanner
                    }

                    // Metadata
                    metadataSection(show)

                    // Genre chips
                    if !show.genres.isEmpty {
                        genreChips(show.genres)
                    }

                    // TMDB Rating
                    if show.voteAverage > 0 {
                        ratingRow(show.voteAverage)
                    }

                    // Save / Status button
                    watchlistButton

                    // Overview
                    if !show.overview.isEmpty {
                        overviewSection(show.overview)
                    }

                    // Streaming links
                    if !viewModel.streamingLinks.isEmpty {
                        streamingSection
                    }

                    Divider()

                    // Season selector (hidden for movies)
                    if show.mediaType != .movie && viewModel.seasons.count > 0 {
                        seasonSelector
                    }

                    // Episode list
                    episodeList(show)
                }
                .padding(.horizontal, GlassTokens.Padding.horizontal)
            }
        }
    }

    // MARK: - Hero

    private func heroSection(_ show: Show) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let backdropPath = show.backdropPath,
                   let url = APIConfig.backdropHeroURL(backdropPath) {
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
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            // Gradient fade
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .offset(y: 60)
        }
    }

    // MARK: - Metadata

    private func metadataSection(_ show: Show) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(show.title)
                .font(.showTitle)

            HStack(spacing: 8) {
                if let date = show.firstAirDate {
                    let formatter: DateFormatter = {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy"
                        return f
                    }()
                    Text(formatter.string(from: date))
                        .font(.metadata)
                        .foregroundStyle(.secondary)
                }

                if let network = show.networks.first {
                    Text(network)
                        .font(.metadata)
                        .foregroundStyle(.secondary)
                }

                statusBadge(show.status)
            }
        }
    }

    private func statusBadge(_ status: ShowStatus) -> some View {
        Text(status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: ShowStatus) -> Color {
        switch status {
        case .airing: .green
        case .ended: .secondary
        case .upcoming: .blue
        case .cancelled: .red
        }
    }

    // MARK: - Genres

    private func genreChips(_ genres: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5), in: Capsule())
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Rating

    private func ratingRow(_ rating: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(String(format: "%.1f", rating))
                .font(.headline)
            Text("/ 10")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Watchlist Button

    private var watchlistButton: some View {
        Group {
            if let status = viewModel.watchlistStatus {
                Menu {
                    ForEach(WatchStatus.allCases, id: \.self) { ws in
                        Button {
                            viewModel.changeWatchlistStatus(ws, context: modelContext)
                        } label: {
                            Label(ws.displayName, systemImage: ws == status ? "checkmark.circle.fill" : "circle")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        viewModel.removeFromWatchlist(context: modelContext)
                    } label: {
                        Label("Remove from Watchlist", systemImage: "bookmark.slash")
                    }
                } label: {
                    Label(status.displayName, systemImage: "bookmark.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(AppColors.accent)
                }
            } else {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    viewModel.saveToWatchlist(status: .watching, context: modelContext)
                } label: {
                    Label("Save to Watchlist", systemImage: "bookmark")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5), in: Capsule())
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Overview

    private func overviewSection(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.secondary)
            .lineLimit(4)
    }

    // MARK: - Streaming Links

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where to Watch")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.streamingLinks) { link in
                        streamingPill(link)
                    }
                }
            }

            Text("Streaming data provided by JustWatch via TMDB")
                .font(.caption2)
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }

    private func streamingPill(_ link: StreamingLink) -> some View {
        Button {
            if let urlString = link.universalLinkURL, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: link.webURL) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                if let url = APIConfig.posterListURL(link.logoPath) {
                    KFImage(url)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Text(link.providerName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stale Banner

    private var staleBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
            Text("Content may be outdated")
        }
        .font(.caption)
        .foregroundStyle(.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Season Selector

    private var seasonSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seasons")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.seasons, id: \.id) { season in
                        Button {
                            Task {
                                await viewModel.selectSeason(
                                    season.seasonNumber,
                                    tmdbId: tmdbId,
                                    context: modelContext
                                )
                            }
                        } label: {
                            Text(season.name)
                                .font(.subheadline.weight(
                                    viewModel.selectedSeason == season.seasonNumber ? .bold : .regular
                                ))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedSeason == season.seasonNumber
                                        ? AppColors.accent.opacity(0.15)
                                        : Color(.systemGray5),
                                    in: Capsule()
                                )
                                .foregroundStyle(
                                    viewModel.selectedSeason == season.seasonNumber
                                        ? AppColors.accent
                                        : .primary
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Episode List

    private func episodeList(_ show: Show) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if show.mediaType != .movie {
                Text("Episodes")
                    .font(.headline)
                    .padding(.top, 4)
            }

            if viewModel.episodes.isEmpty {
                Text("No episodes available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.episodes, id: \.id) { episode in
                    episodeRow(episode, show: show)
                        .onTapGesture {
                            router.navigate(to: .episodeThread(
                                showId: show.tmdbId,
                                season: episode.seasonNumber,
                                episode: episode.episodeNumber
                            ))
                        }
                }
            }
        }
    }

    private func episodeRow(_ episode: Episode, show: Show) -> some View {
        HStack(spacing: 12) {
            // Episode still
            Group {
                if let stillPath = episode.stillPath,
                   let url = APIConfig.stillListURL(stillPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(16/9, contentMode: .fill)
                } else if let posterPath = show.posterPath,
                          let url = APIConfig.posterListURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(Image(systemName: "play.rectangle").foregroundStyle(.secondary))
                }
            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                if show.mediaType != .movie {
                    Text("E\(episode.episodeNumber)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.accent)
                }

                Text(episode.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let airDate = episode.airDate {
                        Text(airDate.relativeString)
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }

                    if let runtime = episode.runtime {
                        Text("\(runtime)m")
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }

                    if episode.commentCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bubble.right")
                            Text("\(episode.commentCount)")
                        }
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
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Error

    private func errorView(_ error: AppError) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.loadShow(tmdbId: tmdbId, mediaType: mediaType, context: modelContext)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - WatchStatus Display Name

extension WatchStatus {
    var displayName: String {
        switch self {
        case .watching: "Currently Watching"
        case .planToWatch: "Plan to Watch"
        case .completed: "Completed"
        }
    }
}
