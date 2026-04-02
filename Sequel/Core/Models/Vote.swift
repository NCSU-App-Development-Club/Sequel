import Foundation

struct Vote: Codable, Identifiable, Sendable, Hashable {
    var id: String
    var commentId: String
    var userId: String
    var value: VoteValue
    var createdAt: Date
}
