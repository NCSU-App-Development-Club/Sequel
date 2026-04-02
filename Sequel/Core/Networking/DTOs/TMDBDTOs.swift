import Foundation

// MARK: - Search

struct TMDBSearchResponse: Codable, Sendable {
    let page: Int
    let results: [TMDBSearchResult]
    let totalPages: Int
    let totalResults: Int
}

struct TMDBSearchResult: Codable, Sendable, Identifiable {
    let id: Int
    let mediaType: String?
    let name: String?
    let title: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let firstAirDate: String?
    let releaseDate: String?
    let genreIds: [Int]?

    var displayTitle: String { name ?? title ?? "Unknown" }
    var displayDate: String? { firstAirDate ?? releaseDate }
    var resolvedMediaType: MediaType {
        mediaType == "movie" ? .movie : .tvShow
    }
}

// MARK: - Show Detail

struct TMDBShowDTO: Codable, Sendable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDBGenre]?
    let networks: [TMDBNetwork]?
    let status: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let numberOfSeasons: Int?
    let seasons: [TMDBSeasonDTO]?
}

struct TMDBGenre: Codable, Sendable {
    let id: Int
    let name: String
}

struct TMDBNetwork: Codable, Sendable {
    let id: Int
    let name: String
    let logoPath: String?
}

// MARK: - Season

struct TMDBSeasonDTO: Codable, Sendable {
    let id: Int?
    let seasonNumber: Int
    let name: String?
    let overview: String?
    let posterPath: String?
    let airDate: String?
    let episodeCount: Int?
    let episodes: [TMDBEpisodeDTO]?
}

// MARK: - Episode

struct TMDBEpisodeDTO: Codable, Sendable {
    let id: Int?
    let episodeNumber: Int
    let name: String?
    let overview: String?
    let stillPath: String?
    let airDate: String?
    let runtime: Int?
    let guestStars: [TMDBGuestStar]?
    let seasonNumber: Int?
}

struct TMDBGuestStar: Codable, Sendable {
    let id: Int
    let name: String
}

// MARK: - Movie

struct TMDBMovieDTO: Codable, Sendable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDBGenre]?
    let status: String?
    let releaseDate: String?
    let voteAverage: Double?
    let runtime: Int?
}

// MARK: - Watch Providers

struct TMDBWatchProvidersResponse: Codable, Sendable {
    let id: Int?
    let results: [String: TMDBCountryProviders]?
}

struct TMDBCountryProviders: Codable, Sendable {
    let link: String?
    let flatrate: [TMDBProviderDTO]?
    let rent: [TMDBProviderDTO]?
    let buy: [TMDBProviderDTO]?
}

struct TMDBProviderDTO: Codable, Sendable {
    let providerId: Int
    let providerName: String
    let logoPath: String
}

// MARK: - Configuration

struct TMDBConfiguration: Codable, Sendable {
    let images: TMDBImagesConfig
}

struct TMDBImagesConfig: Codable, Sendable {
    let baseUrl: String
    let secureBaseUrl: String
    let posterSizes: [String]
    let backdropSizes: [String]
    let stillSizes: [String]
}

// MARK: - Trending

struct TMDBTrendingResponse: Codable, Sendable {
    let page: Int
    let results: [TMDBShowDTO]
}
