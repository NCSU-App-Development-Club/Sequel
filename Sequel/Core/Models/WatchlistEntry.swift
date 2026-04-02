import Foundation
import SwiftData

@Model
final class WatchlistEntry: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var userId: String
    var tmdbId: Int
    var status: WatchStatus
    var dateAdded: Date
    var lastVisited: Date?
    var notificationsEnabled: Bool

    var show: Show?

    init(
        userId: String,
        tmdbId: Int,
        status: WatchStatus = .watching,
        dateAdded: Date = .now,
        lastVisited: Date? = nil,
        notificationsEnabled: Bool = true,
        show: Show? = nil
    ) {
        self.id = "\(userId)_\(tmdbId)"
        self.userId = userId
        self.tmdbId = tmdbId
        self.status = status
        self.dateAdded = dateAdded
        self.lastVisited = lastVisited
        self.notificationsEnabled = notificationsEnabled
        self.show = show
    }
}
