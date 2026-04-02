import Foundation

enum CommentSortMode: String, Codable, Sendable, CaseIterable {
    case hot
    case top
    case new
    case controversial
}

enum TopTimeFilter: String, Codable, Sendable, CaseIterable {
    case today
    case thisWeek
    case allTime
}

enum WatchStatus: String, Codable, Sendable, CaseIterable {
    case watching
    case planToWatch
    case completed
}

enum VoteValue: Int, Codable, Sendable {
    case up = 1
    case down = -1
}

enum StreamingType: String, Codable, Sendable {
    case flatrate
    case rent
    case buy
}

enum NotificationType: String, Codable, Sendable {
    case reply
    case newEpisode
    case trending
    case karmaMilestone
}

enum ShowListSortMode: String, Codable, Sendable, CaseIterable {
    case recentActivity
    case alphabetical
    case nextAiring
}
