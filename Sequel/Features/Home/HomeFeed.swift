import Foundation

// MARK: - Home Feed Data

struct HomeFeed: Sendable {
    let trending: [ShowPreview]
    let watchlistEpisodes: [WatchlistEpisodePreview]
    let recentlyAired: [ShowPreview]
    let discover: [ShowPreview]
}

// MARK: - Lightweight Show Preview (avoids passing @Model across views)

struct ShowPreview: Identifiable, Sendable, Hashable {
    let id: Int  // tmdbId
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let mediaType: MediaType
    let voteAverage: Double
    let genres: [String]
    let networks: [String]
    let firstAirDate: String?
    let status: ShowStatus

    init(from dto: TMDBShowDTO) {
        self.id = dto.id
        self.title = dto.name
        self.posterPath = dto.posterPath
        self.backdropPath = dto.backdropPath
        self.mediaType = .tvShow
        self.voteAverage = dto.voteAverage ?? 0
        self.genres = dto.genres?.map(\.name) ?? []
        self.networks = dto.networks?.map(\.name) ?? []
        self.firstAirDate = dto.firstAirDate
        self.status = ShowStatus.from(tmdbStatus: dto.status)
    }

    init(from show: Show) {
        self.id = show.tmdbId
        self.title = show.title
        self.posterPath = show.posterPath
        self.backdropPath = show.backdropPath
        self.mediaType = show.mediaType
        self.voteAverage = show.voteAverage
        self.genres = show.genres
        self.networks = show.networks
        self.firstAirDate = {
            guard let date = show.firstAirDate else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }()
        self.status = show.status
    }

    var yearString: String? {
        guard let date = firstAirDate, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }
}

// MARK: - Watchlist Episode Preview

struct WatchlistEpisodePreview: Identifiable, Sendable {
    let id: String  // episode composite id
    let showTmdbId: Int
    let showTitle: String
    let posterPath: String?
    let episodeName: String
    let seasonNumber: Int
    let episodeNumber: Int
    let airDate: Date?
    let commentCount: Int
    let mediaType: MediaType

    var episodeLabel: String {
        "S\(seasonNumber)E\(episodeNumber)"
    }
}
