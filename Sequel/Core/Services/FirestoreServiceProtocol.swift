import Foundation

protocol FirestoreServiceProtocol: Sendable {
    // MARK: - User Profile
    func getUserProfile(userId: String) async throws -> UserProfile?
    func createUserProfile(_ profile: UserProfile) async throws
    func updateUserProfile(_ profile: UserProfile) async throws

    // MARK: - Comments
    func fetchComments(
        episodeId: String,
        sortMode: CommentSortMode,
        limit: Int,
        after cursor: String?
    ) async throws -> [Comment]
    func createComment(_ comment: Comment) async throws
    func updateComment(id: String, body: String, editedAt: Date) async throws
    func deleteComment(id: String) async throws
    func addCommentsListener(
        episodeId: String,
        onUpdate: @Sendable @escaping ([Comment]) -> Void
    ) -> ListenerHandle

    // MARK: - Votes
    func getVoteForUser(commentId: String, userId: String) async throws -> Vote?
    func createVote(_ vote: Vote) async throws
    func deleteVote(id: String) async throws

    // MARK: - Watchlist
    func fetchWatchlist(userId: String) async throws -> [UserProfile]
    func addToWatchlist(_ entry: WatchlistEntry) async throws
    func updateWatchlistEntry(_ entry: WatchlistEntry) async throws
    func removeFromWatchlist(id: String) async throws
    func addWatchlistListener(
        userId: String,
        onUpdate: @Sendable @escaping ([WatchlistEntry]) -> Void
    ) -> ListenerHandle
}

/// A handle for detaching a Firestore snapshot listener
final class ListenerHandle: Sendable {
    nonisolated(unsafe) private var removeBlock: (() -> Void)?

    init(remove: @escaping () -> Void) {
        self.removeBlock = remove
    }

    func remove() {
        removeBlock?()
        removeBlock = nil
    }
}
