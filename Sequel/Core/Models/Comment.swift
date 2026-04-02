import Foundation

struct Comment: Codable, Identifiable, Sendable, Hashable {
    var id: String
    var authorId: String
    var authorDisplayName: String
    var authorAvatarURL: String?
    var authorKarma: Int
    var episodeId: String
    var parentCommentId: String?
    var body: String
    var upvoteCount: Int
    var downvoteCount: Int
    var createdAt: Date
    var editedAt: Date?
    var isDeleted: Bool
    var depth: Int

    var netScore: Int { upvoteCount - downvoteCount }
}
