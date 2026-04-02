import Foundation
import SwiftData

@Model
final class Episode {
    @Attribute(.unique) var id: String
    var showTmdbId: Int
    var seasonNumber: Int
    var episodeNumber: Int
    var name: String
    var overview: String?
    var stillPath: String?
    var airDate: Date?
    var runtime: Int?
    var guestStars: [String]
    var commentCount: Int

    var season: Season?

    init(
        showTmdbId: Int,
        seasonNumber: Int,
        episodeNumber: Int,
        name: String = "",
        overview: String? = nil,
        stillPath: String? = nil,
        airDate: Date? = nil,
        runtime: Int? = nil,
        guestStars: [String] = [],
        commentCount: Int = 0,
        season: Season? = nil
    ) {
        self.id = "\(showTmdbId)_S\(seasonNumber)E\(episodeNumber)"
        self.showTmdbId = showTmdbId
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.name = name
        self.overview = overview
        self.stillPath = stillPath
        self.airDate = airDate
        self.runtime = runtime
        self.guestStars = guestStars
        self.commentCount = commentCount
        self.season = season
    }
}
