import Foundation

struct UserProfile: Codable, Identifiable, Sendable, Hashable {
    var id: String
    var displayName: String
    var avatarURL: String?
    var bio: String?
    var karma: Int
    var joinedAt: Date
    var favoriteShowIds: [Int]
    var notificationPreferences: NotificationPrefs
}

struct NotificationPrefs: Codable, Sendable, Hashable {
    var repliesEnabled: Bool
    var newEpisodesEnabled: Bool
    var trendingEnabled: Bool
    var karmaEnabled: Bool
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    var mutedShowIds: [Int]

    static let `default` = NotificationPrefs(
        repliesEnabled: true,
        newEpisodesEnabled: true,
        trendingEnabled: true,
        karmaEnabled: true,
        quietHoursStart: nil,
        quietHoursEnd: nil,
        mutedShowIds: []
    )
}
