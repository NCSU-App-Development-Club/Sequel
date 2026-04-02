import Foundation
import SwiftData

@Model
final class Show: @unchecked Sendable {
    @Attribute(.unique) var tmdbId: Int
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var genres: [String]
    var networks: [String]
    var status: ShowStatus
    var firstAirDate: Date?
    var voteAverage: Double
    var mediaType: MediaType
    var seasonCount: Int
    var lastRefreshed: Date
    var followerCount: Int

    @Relationship(deleteRule: .cascade, inverse: \Season.show)
    var seasons: [Season]

    init(
        tmdbId: Int,
        title: String,
        overview: String = "",
        posterPath: String? = nil,
        backdropPath: String? = nil,
        genres: [String] = [],
        networks: [String] = [],
        status: ShowStatus = .airing,
        firstAirDate: Date? = nil,
        voteAverage: Double = 0,
        mediaType: MediaType = .tvShow,
        seasonCount: Int = 0,
        lastRefreshed: Date = .now,
        followerCount: Int = 0,
        seasons: [Season] = []
    ) {
        self.tmdbId = tmdbId
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.genres = genres
        self.networks = networks
        self.status = status
        self.firstAirDate = firstAirDate
        self.voteAverage = voteAverage
        self.mediaType = mediaType
        self.seasonCount = seasonCount
        self.lastRefreshed = lastRefreshed
        self.followerCount = followerCount
        self.seasons = seasons
    }
}
