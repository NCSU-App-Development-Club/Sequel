import Foundation

final class FirestoreService: FirestoreServiceProtocol, @unchecked Sendable {
    static let shared = FirestoreService()

    // MARK: - User Profile

    func getUserProfile(userId: String) async throws -> UserProfile? {
        // TODO: Implement via Firestore db.collection("users").document(userId).getDocument()
        return nil
    }

    func createUserProfile(_ profile: UserProfile) async throws {
        // TODO: Implement via Firestore db.collection("users").document(profile.id).setData()
    }

    func updateUserProfile(_ profile: UserProfile) async throws {
        // TODO: Implement via Firestore update
    }

    // MARK: - Comments

    func fetchComments(
        episodeId: String,
        sortMode: CommentSortMode,
        limit: Int,
        after cursor: String?
    ) async throws -> [Comment] {
        // TODO: Implement cursor-paginated Firestore query ordered by sortMode
        return []
    }

    func createComment(_ comment: Comment) async throws {
        // TODO: Implement via Firestore db.collection("comments").document(comment.id).setData()
    }

    func updateComment(id: String, body: String, editedAt: Date) async throws {
        // TODO: Implement via Firestore update
    }

    func deleteComment(id: String) async throws {
        // TODO: Set isDeleted = true (soft delete preserves thread integrity)
    }

    func addCommentsListener(
        episodeId: String,
        onUpdate: @Sendable @escaping ([Comment]) -> Void
    ) -> ListenerHandle {
        // TODO: Implement via Firestore .addSnapshotListener — detach on remove()
        return ListenerHandle(remove: {})
    }

    // MARK: - Votes

    func getVoteForUser(commentId: String, userId: String) async throws -> Vote? {
        // TODO: Implement via Firestore votes/{commentId}_{userId}
        return nil
    }

    func createVote(_ vote: Vote) async throws {
        // TODO: Implement via Firestore db.collection("votes").document(vote.id).setData()
    }

    func deleteVote(id: String) async throws {
        // TODO: Implement via Firestore delete
    }

    // MARK: - Watchlist

    func fetchWatchlist(userId: String) async throws -> [UserProfile] {
        // TODO: Implement via Firestore users/{userId}/watchlist
        return []
    }

    func addToWatchlist(_ entry: WatchlistEntry) async throws {
        // TODO: Implement via Firestore users/{userId}/watchlist/{tmdbId}
    }

    func updateWatchlistEntry(_ entry: WatchlistEntry) async throws {
        // TODO: Implement via Firestore update
    }

    func removeFromWatchlist(id: String) async throws {
        // TODO: Implement via Firestore delete
    }

    func addWatchlistListener(
        userId: String,
        onUpdate: @Sendable @escaping ([WatchlistEntry]) -> Void
    ) -> ListenerHandle {
        // TODO: Implement via Firestore snapshot listener
        return ListenerHandle(remove: {})
    }
}
