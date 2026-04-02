import Foundation

struct AppNotification: Codable, Identifiable, Sendable, Hashable {
    var id: String
    var userId: String
    var type: NotificationType
    var title: String
    var body: String
    var showTmdbId: Int?
    var episodeId: String?
    var commentId: String?
    var createdAt: Date
    var isRead: Bool
}
