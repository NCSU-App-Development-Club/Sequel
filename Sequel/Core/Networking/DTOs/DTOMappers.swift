import Foundation

// MARK: - Search Result (unified type for display)

struct SearchResult: Identifiable, Sendable, Hashable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let mediaType: MediaType
    let firstAirDate: String?
    let voteAverage: Double

    init(from dto: TMDBSearchResult) {
        self.id = dto.id
        self.title = dto.displayTitle
        self.overview = dto.overview ?? ""
        self.posterPath = dto.posterPath
        self.backdropPath = dto.backdropPath
        self.mediaType = dto.resolvedMediaType
        self.firstAirDate = dto.displayDate
        self.voteAverage = dto.voteAverage ?? 0
    }
}

// MARK: - Show from DTO

extension Show {
    convenience init(from dto: TMDBShowDTO) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        self.init(
            tmdbId: dto.id,
            title: dto.name,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            genres: dto.genres?.map(\.name) ?? [],
            networks: dto.networks?.map(\.name) ?? [],
            status: ShowStatus.from(tmdbStatus: dto.status),
            firstAirDate: dto.firstAirDate.flatMap { dateFormatter.date(from: $0) },
            voteAverage: dto.voteAverage ?? 0,
            mediaType: .tvShow,
            seasonCount: dto.numberOfSeasons ?? 0
        )
    }

    convenience init(from dto: TMDBMovieDTO) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        self.init(
            tmdbId: dto.id,
            title: dto.title,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            genres: dto.genres?.map(\.name) ?? [],
            status: .ended,
            firstAirDate: dto.releaseDate.flatMap { dateFormatter.date(from: $0) },
            voteAverage: dto.voteAverage ?? 0,
            mediaType: .movie,
            seasonCount: 1
        )
    }
}

// MARK: - Season from DTO

extension Season {
    convenience init(from dto: TMDBSeasonDTO, showTmdbId: Int) {
        self.init(
            showTmdbId: showTmdbId,
            seasonNumber: dto.seasonNumber,
            name: dto.name ?? "Season \(dto.seasonNumber)",
            overview: dto.overview,
            posterPath: dto.posterPath,
            episodeCount: dto.episodeCount ?? dto.episodes?.count ?? 0
        )
    }
}

// MARK: - Episode from DTO

extension Episode {
    convenience init(from dto: TMDBEpisodeDTO, showTmdbId: Int, seasonNumber: Int) {
        self.init(
            showTmdbId: showTmdbId,
            seasonNumber: seasonNumber,
            episodeNumber: dto.episodeNumber,
            name: dto.name ?? "Episode \(dto.episodeNumber)",
            overview: dto.overview,
            stillPath: dto.stillPath,
            runtime: dto.runtime,
            guestStars: dto.guestStars?.map(\.name) ?? []
        )
    }
}

// MARK: - ShowStatus from TMDB string

extension ShowStatus {
    static func from(tmdbStatus: String?) -> ShowStatus {
        switch tmdbStatus?.lowercased() {
        case "returning series", "in production": return .airing
        case "ended": return .ended
        case "planned": return .upcoming
        case "canceled", "cancelled": return .cancelled
        default: return .airing
        }
    }
}

// MARK: - StreamingLink from TMDB providers

extension StreamingLink {
    static func from(providers: TMDBCountryProviders) -> [StreamingLink] {
        var links: [StreamingLink] = []
        let webURL = providers.link ?? ""

        for provider in providers.flatrate ?? [] {
            links.append(StreamingLink(
                id: provider.providerId,
                providerName: provider.providerName,
                logoPath: provider.logoPath,
                webURL: webURL,
                type: .flatrate
            ))
        }
        for provider in providers.rent ?? [] {
            links.append(StreamingLink(
                id: provider.providerId,
                providerName: provider.providerName,
                logoPath: provider.logoPath,
                webURL: webURL,
                type: .rent
            ))
        }
        for provider in providers.buy ?? [] {
            links.append(StreamingLink(
                id: provider.providerId,
                providerName: provider.providerName,
                logoPath: provider.logoPath,
                webURL: webURL,
                type: .buy
            ))
        }
        return links
    }
}
