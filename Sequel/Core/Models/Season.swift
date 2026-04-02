import Foundation
import SwiftData

@Model
final class Season: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var showTmdbId: Int
    var seasonNumber: Int
    var name: String
    var overview: String?
    var posterPath: String?
    var airDate: Date?
    var episodeCount: Int

    var show: Show?

    @Relationship(deleteRule: .cascade, inverse: \Episode.season)
    var episodes: [Episode]

    init(
        showTmdbId: Int,
        seasonNumber: Int,
        name: String = "",
        overview: String? = nil,
        posterPath: String? = nil,
        airDate: Date? = nil,
        episodeCount: Int = 0,
        show: Show? = nil,
        episodes: [Episode] = []
    ) {
        self.id = "\(showTmdbId)_S\(seasonNumber)"
        self.showTmdbId = showTmdbId
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.posterPath = posterPath
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.show = show
        self.episodes = episodes
    }
}
