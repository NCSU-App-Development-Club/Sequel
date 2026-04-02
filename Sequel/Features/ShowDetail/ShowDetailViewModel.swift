import Foundation
import SwiftData
import Kingfisher

@Observable
final class ShowDetailViewModel {
    private(set) var show: Show?
    private(set) var episodes: [Episode] = []
    private(set) var streamingLinks: [StreamingLink] = []
    private(set) var seasons: [Season] = []
    private(set) var isLoading = false
    private(set) var isStale = false
    private(set) var error: AppError?
    var selectedSeason: Int = 1
    var watchlistStatus: WatchStatus?

    private let tmdbService: TMDBServiceProtocol
    private let cacheService = TMDBCacheService.shared

    init(tmdbService: TMDBServiceProtocol = TMDBService.shared) {
        self.tmdbService = tmdbService
    }

    // MARK: - Load Show

    func loadShow(tmdbId: Int, mediaType: MediaType, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        // Check cache first
        if let cachedShow = cacheService.fetchCachedShow(tmdbId: tmdbId, context: context) {
            show = cachedShow
            loadCachedData(tmdbId: tmdbId, context: context)
            loadWatchlistStatus(tmdbId: tmdbId, context: context)
            return
        }

        // Check stale cache (serve while refreshing)
        if let staleShow = cacheService.fetchCachedShowIgnoringTTL(tmdbId: tmdbId, context: context) {
            show = staleShow
            isStale = true
            loadCachedData(tmdbId: tmdbId, context: context)
            loadWatchlistStatus(tmdbId: tmdbId, context: context)
        }

        // Fetch from TMDB
        do {
            if mediaType == .movie {
                try await loadMovie(id: tmdbId, context: context)
            } else {
                try await loadTVShow(id: tmdbId, context: context)
            }
            isStale = false
            error = nil
        } catch {
            if show == nil {
                self.error = .from(error)
            }
            // If we have stale data, we keep showing it with the stale banner
        }

        loadWatchlistStatus(tmdbId: tmdbId, context: context)
    }

    // MARK: - TV Show

    private func loadTVShow(id: Int, context: ModelContext) async throws {
        let dto = try await tmdbService.fetchShow(id: id)
        let newShow = Show(from: dto)
        cacheService.cacheShow(newShow, context: context)
        show = cacheService.fetchCachedShowIgnoringTTL(tmdbId: id, context: context) ?? newShow

        // Cache seasons from batch response
        if let seasonDTOs = dto.seasons?.filter({ $0.seasonNumber > 0 }) {
            let seasonModels = seasonDTOs.map { Season(from: $0, showTmdbId: id) }
            cacheService.cacheSeasons(seasonModels, for: id, context: context)
            seasons = cacheService.fetchCachedSeasons(showTmdbId: id, context: context)
                .filter { $0.seasonNumber > 0 }

            // Load first season episodes
            if let firstSeason = seasons.first {
                selectedSeason = firstSeason.seasonNumber
                await selectSeason(firstSeason.seasonNumber, tmdbId: id, context: context)
            }
        }

        // Load watch providers
        await loadStreamingLinks(showId: id)
    }

    // MARK: - Movie

    private func loadMovie(id: Int, context: ModelContext) async throws {
        let dto = try await tmdbService.fetchMovie(id: id)
        let newShow = Show(from: dto)
        cacheService.cacheShow(newShow, context: context)
        show = cacheService.fetchCachedShowIgnoringTTL(tmdbId: id, context: context) ?? newShow

        // Create single season + episode for movie
        let season = Season(
            showTmdbId: id,
            seasonNumber: 1,
            name: newShow.title,
            episodeCount: 1
        )
        cacheService.cacheSeasons([season], for: id, context: context)
        seasons = [season]

        let episode = Episode(
            showTmdbId: id,
            seasonNumber: 1,
            episodeNumber: 1,
            name: newShow.title,
            overview: newShow.overview,
            stillPath: newShow.backdropPath,
            runtime: dto.runtime
        )
        if let cachedSeason = cacheService.fetchCachedSeasons(showTmdbId: id, context: context).first {
            cacheService.cacheEpisodes([episode], for: cachedSeason, context: context)
        }
        episodes = [episode]
        selectedSeason = 1

        // Load watch providers for movie
        await loadMovieStreamingLinks(movieId: id)
    }

    // MARK: - Season Selection

    func selectSeason(_ seasonNumber: Int, tmdbId: Int, context: ModelContext) async {
        selectedSeason = seasonNumber

        // Try cache first
        let cached = cacheService.fetchCachedEpisodes(showTmdbId: tmdbId, seasonNumber: seasonNumber, context: context)
        if !cached.isEmpty {
            episodes = cached
            return
        }

        // Fetch from TMDB
        do {
            let seasonDTO = try await tmdbService.fetchSeason(showId: tmdbId, seasonNumber: seasonNumber)
            let episodeModels = (seasonDTO.episodes ?? []).map {
                Episode(from: $0, showTmdbId: tmdbId, seasonNumber: seasonNumber)
            }

            // Cache
            if let season = cacheService.fetchCachedSeasons(showTmdbId: tmdbId, context: context)
                .first(where: { $0.seasonNumber == seasonNumber }) {
                cacheService.cacheEpisodes(episodeModels, for: season, context: context)
            }
            episodes = cacheService.fetchCachedEpisodes(showTmdbId: tmdbId, seasonNumber: seasonNumber, context: context)
            if episodes.isEmpty {
                episodes = episodeModels
            }

            // Prefetch episode stills
            prefetchEpisodeImages(episodeModels)
        } catch {
            self.error = .from(error)
        }
    }

    // MARK: - Streaming Links

    private func loadStreamingLinks(showId: Int) async {
        do {
            let response = try await tmdbService.fetchWatchProviders(showId: showId)
            let region = Locale.current.region?.identifier ?? "US"
            if let countryProviders = response.results?[region] {
                streamingLinks = StreamingLink.from(providers: countryProviders)
            }
        } catch {
            // Non-critical — streaming links are optional
            streamingLinks = []
        }
    }

    private func loadMovieStreamingLinks(movieId: Int) async {
        // For movies, watch providers come from the movie endpoint's append_to_response
        // The TMDBService already fetches with append_to_response=watch/providers
        // but the DTO doesn't expose it directly. Use the same providers endpoint pattern.
        do {
            var components = URLComponents(string: "\(APIConfig.tmdbBaseURL)/movie/\(movieId)/watch/providers")!
            components.queryItems = [URLQueryItem(name: "api_key", value: APIConfig.tmdbAPIKey)]
            if let url = components.url {
                let response: TMDBWatchProvidersResponse = try await APIClient.shared.request(url: url)
                let region = Locale.current.region?.identifier ?? "US"
                if let countryProviders = response.results?[region] {
                    streamingLinks = StreamingLink.from(providers: countryProviders)
                }
            }
        } catch {
            streamingLinks = []
        }
    }

    // MARK: - Watchlist

    func saveToWatchlist(status: WatchStatus, context: ModelContext) {
        guard let show = show else { return }
        let userId = "local_user"
        let entry = WatchlistEntry(
            userId: userId,
            tmdbId: show.tmdbId,
            status: status,
            show: show
        )
        context.insert(entry)
        try? context.save()
        watchlistStatus = status
    }

    func removeFromWatchlist(context: ModelContext) {
        guard let show = show else { return }
        let userId = "local_user"
        let tmdbId = show.tmdbId
        let descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate<WatchlistEntry> {
                $0.userId == userId && $0.tmdbId == tmdbId
            }
        )
        if let entry = try? context.fetch(descriptor).first {
            context.delete(entry)
            try? context.save()
        }
        watchlistStatus = nil
    }

    func changeWatchlistStatus(_ status: WatchStatus, context: ModelContext) {
        guard let show = show else { return }
        let userId = "local_user"
        let tmdbId = show.tmdbId
        let descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate<WatchlistEntry> {
                $0.userId == userId && $0.tmdbId == tmdbId
            }
        )
        if let entry = try? context.fetch(descriptor).first {
            entry.status = status
            try? context.save()
        }
        watchlistStatus = status
    }

    // MARK: - Private Helpers

    private func loadCachedData(tmdbId: Int, context: ModelContext) {
        seasons = cacheService.fetchCachedSeasons(showTmdbId: tmdbId, context: context)
            .filter { $0.seasonNumber > 0 }
        if let firstSeason = seasons.first {
            selectedSeason = firstSeason.seasonNumber
            episodes = cacheService.fetchCachedEpisodes(showTmdbId: tmdbId, seasonNumber: firstSeason.seasonNumber, context: context)
        }
    }

    private func loadWatchlistStatus(tmdbId: Int, context: ModelContext) {
        let userId = "local_user"
        let descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate<WatchlistEntry> {
                $0.userId == userId && $0.tmdbId == tmdbId
            }
        )
        watchlistStatus = try? context.fetch(descriptor).first?.status
    }

    private func prefetchEpisodeImages(_ episodes: [Episode]) {
        let urls = episodes.compactMap { episode -> URL? in
            guard let path = episode.stillPath else { return nil }
            return APIConfig.stillListURL(path)
        }
        guard !urls.isEmpty else { return }
        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
    }
}
