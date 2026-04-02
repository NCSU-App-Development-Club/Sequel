import Foundation
import SwiftData

@Observable
final class EpisodeThreadViewModel {
    private(set) var show: Show?
    private(set) var episode: Episode?
    private(set) var streamingLinks: [StreamingLink] = []
    private(set) var isLoading = false
    private(set) var error: AppError?
    var isOverviewExpanded = false
    var isStreamingExpanded = false

    private let tmdbService: TMDBServiceProtocol
    private let cacheService = TMDBCacheService.shared

    init(tmdbService: TMDBServiceProtocol = TMDBService.shared) {
        self.tmdbService = tmdbService
    }

    func loadEpisode(showId: Int, season: Int, episodeNumber: Int, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        // Load show from cache
        show = cacheService.fetchCachedShowIgnoringTTL(tmdbId: showId, context: context)

        // Load episode from cache
        let episodes = cacheService.fetchCachedEpisodes(
            showTmdbId: showId,
            seasonNumber: season,
            context: context
        )
        episode = episodes.first(where: { $0.episodeNumber == episodeNumber })

        // If no cached episode, fetch the season
        if episode == nil {
            do {
                let seasonDTO = try await tmdbService.fetchSeason(showId: showId, seasonNumber: season)
                let episodeModels = (seasonDTO.episodes ?? []).map {
                    Episode(from: $0, showTmdbId: showId, seasonNumber: season)
                }

                // Cache
                let cachedSeasons = cacheService.fetchCachedSeasons(showTmdbId: showId, context: context)
                if let cachedSeason = cachedSeasons.first(where: { $0.seasonNumber == season }) {
                    cacheService.cacheEpisodes(episodeModels, for: cachedSeason, context: context)
                }

                episode = episodeModels.first(where: { $0.episodeNumber == episodeNumber })
            } catch {
                self.error = .from(error)
            }
        }

        // Load streaming links
        if let show = show {
            await loadStreamingLinks(showId: show.tmdbId)
        }
    }

    private func loadStreamingLinks(showId: Int) async {
        do {
            let response = try await tmdbService.fetchWatchProviders(showId: showId)
            let region = Locale.current.region?.identifier ?? "US"
            if let countryProviders = response.results?[region] {
                streamingLinks = StreamingLink.from(providers: countryProviders)
            }
        } catch {
            streamingLinks = []
        }
    }
}
