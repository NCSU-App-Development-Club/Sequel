import Foundation
import SwiftData

/// Manages SwiftData caching of TMDB show/season/episode data with 6h TTL.
@MainActor
final class TMDBCacheService {
    static let shared = TMDBCacheService()

    private let cacheDuration: TimeInterval = 6 * 60 * 60  // 6 hours

    private init() {}

    // MARK: - Show Cache

    func fetchCachedShow(tmdbId: Int, context: ModelContext) -> Show? {
        let descriptor = FetchDescriptor<Show>(
            predicate: #Predicate<Show> { $0.tmdbId == tmdbId }
        )
        guard let show = try? context.fetch(descriptor).first else { return nil }

        // Check TTL
        if Date.now.timeIntervalSince(show.lastRefreshed) < cacheDuration {
            return show
        }
        return nil  // stale — caller should refetch
    }

    func fetchCachedShowIgnoringTTL(tmdbId: Int, context: ModelContext) -> Show? {
        let descriptor = FetchDescriptor<Show>(
            predicate: #Predicate<Show> { $0.tmdbId == tmdbId }
        )
        return try? context.fetch(descriptor).first
    }

    func isStale(_ show: Show) -> Bool {
        Date.now.timeIntervalSince(show.lastRefreshed) >= cacheDuration
    }

    func cacheShow(_ show: Show, context: ModelContext) {
        // Check if show already exists
        if let existing = fetchCachedShowIgnoringTTL(tmdbId: show.tmdbId, context: context) {
            // Update existing
            existing.title = show.title
            existing.overview = show.overview
            existing.posterPath = show.posterPath
            existing.backdropPath = show.backdropPath
            existing.genres = show.genres
            existing.networks = show.networks
            existing.status = show.status
            existing.firstAirDate = show.firstAirDate
            existing.voteAverage = show.voteAverage
            existing.mediaType = show.mediaType
            existing.seasonCount = show.seasonCount
            existing.lastRefreshed = .now
        } else {
            show.lastRefreshed = .now
            context.insert(show)
        }
        try? context.save()
    }

    // MARK: - Season / Episode Cache

    func cacheSeasons(_ seasons: [Season], for showTmdbId: Int, context: ModelContext) {
        let show = fetchCachedShowIgnoringTTL(tmdbId: showTmdbId, context: context)

        for season in seasons {
            season.show = show
            context.insert(season)
        }
        try? context.save()
    }

    func cacheEpisodes(_ episodes: [Episode], for season: Season, context: ModelContext) {
        for episode in episodes {
            episode.season = season
            context.insert(episode)
        }
        try? context.save()
    }

    func fetchCachedEpisodes(showTmdbId: Int, seasonNumber: Int, context: ModelContext) -> [Episode] {
        let descriptor = FetchDescriptor<Episode>(
            predicate: #Predicate<Episode> {
                $0.showTmdbId == showTmdbId && $0.seasonNumber == seasonNumber
            },
            sortBy: [SortDescriptor(\.episodeNumber)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetchCachedSeasons(showTmdbId: Int, context: ModelContext) -> [Season] {
        let descriptor = FetchDescriptor<Season>(
            predicate: #Predicate<Season> { $0.showTmdbId == showTmdbId },
            sortBy: [SortDescriptor(\.seasonNumber)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
