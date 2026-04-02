import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    private(set) var loadingState: LoadingState<HomeFeed> = .idle
    private(set) var error: AppError?

    private let tmdbService: TMDBServiceProtocol

    init(tmdbService: TMDBServiceProtocol = TMDBService.shared) {
        self.tmdbService = tmdbService
    }

    // MARK: - Load Feed

    func loadFeed(context: ModelContext) async {
        guard case .idle = loadingState else { return }
        loadingState = .loading
        await fetchFeed(context: context)
    }

    func refresh(context: ModelContext) async {
        await fetchFeed(context: context)
    }

    private func fetchFeed(context: ModelContext) async {
        do {
            // Parallel fetch trending data from TMDB
            let trendingDTOs = try await tmdbService.fetchTrending()

            // Build sections from trending data
            let allPreviews = trendingDTOs.map { ShowPreview(from: $0) }

            // Section A: Trending — first 10
            let trending = Array(allPreviews.prefix(10))

            // Section B: Watchlist episodes — from local SwiftData
            let watchlistEpisodes = fetchWatchlistEpisodes(context: context)

            // Section C: Recently Aired — subset of trending (different slice)
            let recentlyAired = Array(allPreviews.dropFirst(3).prefix(7))

            // Section D: Discover — curated from remaining
            let discover = Array(allPreviews.suffix(5))

            let feed = HomeFeed(
                trending: trending,
                watchlistEpisodes: watchlistEpisodes,
                recentlyAired: recentlyAired,
                discover: discover
            )
            loadingState = .loaded(feed)
            error = nil
        } catch {
            self.error = .from(error)
            loadingState = .error(.from(error))
        }
    }

    // MARK: - Watchlist

    private func fetchWatchlistEpisodes(context: ModelContext) -> [WatchlistEpisodePreview] {
        let descriptor = FetchDescriptor<WatchlistEntry>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        guard let entries = try? context.fetch(descriptor) else { return [] }

        return entries.compactMap { entry -> WatchlistEpisodePreview? in
            guard let show = entry.show else { return nil }
            let showTmdbId = show.tmdbId

            let episodeDescriptor = FetchDescriptor<Episode>(
                predicate: #Predicate<Episode> { $0.showTmdbId == showTmdbId },
                sortBy: [SortDescriptor(\.seasonNumber, order: .reverse),
                         SortDescriptor(\.episodeNumber, order: .reverse)]
            )
            let latestEpisode = try? context.fetch(episodeDescriptor).first

            return WatchlistEpisodePreview(
                id: latestEpisode?.id ?? "\(show.tmdbId)_latest",
                showTmdbId: show.tmdbId,
                showTitle: show.title,
                posterPath: show.posterPath,
                episodeName: latestEpisode?.name ?? "Latest Episode",
                seasonNumber: latestEpisode?.seasonNumber ?? 1,
                episodeNumber: latestEpisode?.episodeNumber ?? 1,
                airDate: latestEpisode?.airDate,
                commentCount: latestEpisode?.commentCount ?? 0,
                mediaType: show.mediaType
            )
        }
    }

    // MARK: - Bookmark

    func toggleBookmark(showPreview: ShowPreview, context: ModelContext) {
        let tmdbId = showPreview.id

        // Fetch all watchlist entries and filter in memory
        let allDescriptor = FetchDescriptor<WatchlistEntry>()
        let allEntries = (try? context.fetch(allDescriptor)) ?? []
        let existing = allEntries.first { $0.userId == "local_user" && $0.tmdbId == tmdbId }

        if let existing {
            context.delete(existing)
        } else {
            // Add to watchlist — ensure show exists in SwiftData first
            var show = TMDBCacheService.shared.fetchCachedShowIgnoringTTL(tmdbId: tmdbId, context: context)
            if show == nil {
                let newShow = Show(
                    tmdbId: showPreview.id,
                    title: showPreview.title,
                    posterPath: showPreview.posterPath,
                    backdropPath: showPreview.backdropPath,
                    genres: showPreview.genres,
                    networks: showPreview.networks,
                    status: showPreview.status,
                    voteAverage: showPreview.voteAverage,
                    mediaType: showPreview.mediaType
                )
                context.insert(newShow)
                show = newShow
            }

            let entry = WatchlistEntry(
                userId: "local_user",
                tmdbId: tmdbId,
                status: .watching,
                show: show
            )
            context.insert(entry)
        }
        try? context.save()
    }

    func isBookmarked(tmdbId: Int, context: ModelContext) -> Bool {
        let allDescriptor = FetchDescriptor<WatchlistEntry>()
        let allEntries = (try? context.fetch(allDescriptor)) ?? []
        return allEntries.contains { $0.userId == "local_user" && $0.tmdbId == tmdbId }
    }
}
