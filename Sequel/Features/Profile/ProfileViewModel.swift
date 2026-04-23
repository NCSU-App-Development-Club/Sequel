import Foundation

@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile
    private(set) var commentHistory: [ProfileCommentHistoryItem]
    private(set) var visibleCommentCount = 5

    var visibleComments: [ProfileCommentHistoryItem] {
        Array(commentHistory.prefix(visibleCommentCount))
    }

    var hasMoreComments: Bool {
        visibleCommentCount < commentHistory.count
    }

    var trackedShowCount: Int {
        profile.favoriteShowIds.count
    }

    var upvoteKarma: Int {
        max(profile.karma + 47, 0)
    }

    var downvoteKarma: Int {
        47
    }

    init(
        profile: UserProfile = .mock,
        commentHistory: [ProfileCommentHistoryItem] = ProfileCommentHistoryItem.mockItems
    ) {
        self.profile = profile
        self.commentHistory = commentHistory.sorted { $0.createdAt > $1.createdAt }
    }

    func loadMoreComments() {
        guard hasMoreComments else { return }
        visibleCommentCount = min(visibleCommentCount + 5, commentHistory.count)
    }
}

struct ProfileCommentHistoryItem: Identifiable, Hashable, Sendable {
    let id: String
    let showId: Int
    let showTitle: String
    let seasonNumber: Int
    let episodeNumber: Int
    let episodeTitle: String
    let body: String
    let netVotes: Int
    let createdAt: Date

    var episodeLabel: String {
        "S\(seasonNumber) E\(episodeNumber) • \(episodeTitle)"
    }
}

extension UserProfile {
    static let mock = UserProfile(
        id: "local-profile",
        displayName: "sequel_fan",
        avatarURL: nil,
        bio: "Tracking prestige dramas, comedies, and every finale thread worth arguing about.",
        karma: 1248,
        joinedAt: Calendar.current.date(byAdding: .month, value: -8, to: .now) ?? .now,
        favoriteShowIds: [1399, 66732, 60625, 95396, 71712, 93405, 110492, 76479],
        notificationPreferences: .default
    )
}

extension ProfileCommentHistoryItem {
    static let mockItems: [ProfileCommentHistoryItem] = [
        ProfileCommentHistoryItem(
            id: "comment-1",
            showId: 1399,
            showTitle: "The Last Kingdom",
            seasonNumber: 4,
            episodeNumber: 8,
            episodeTitle: "The Siege",
            body: "That final scene completely changes how I read the whole season. The setup was quiet, but the payoff was huge.",
            netVotes: 42,
            createdAt: .now.addingTimeInterval(-900)
        ),
        ProfileCommentHistoryItem(
            id: "comment-2",
            showId: 66732,
            showTitle: "Stranger Things",
            seasonNumber: 2,
            episodeNumber: 6,
            episodeTitle: "The Spy",
            body: "The sound design did so much work here. You can feel the threat before anyone says a word.",
            netVotes: 31,
            createdAt: .now.addingTimeInterval(-4_200)
        ),
        ProfileCommentHistoryItem(
            id: "comment-3",
            showId: 60625,
            showTitle: "Rick and Morty",
            seasonNumber: 6,
            episodeNumber: 3,
            episodeTitle: "Bethic Twinstinct",
            body: "This was funny, but the family fallout is the part I want the show to actually keep carrying forward.",
            netVotes: 18,
            createdAt: .now.addingTimeInterval(-9_400)
        ),
        ProfileCommentHistoryItem(
            id: "comment-4",
            showId: 95396,
            showTitle: "Severance",
            seasonNumber: 1,
            episodeNumber: 9,
            episodeTitle: "The We We Are",
            body: "The pacing in this finale is ridiculous. Every cut makes the next reveal feel even more stressful.",
            netVotes: 97,
            createdAt: .now.addingTimeInterval(-18_000)
        ),
        ProfileCommentHistoryItem(
            id: "comment-5",
            showId: 71712,
            showTitle: "The Good Place",
            seasonNumber: 4,
            episodeNumber: 13,
            episodeTitle: "Whenever You're Ready",
            body: "Still one of the cleanest endings for a sitcom. It closes the philosophy and the character arcs at the same time.",
            netVotes: 64,
            createdAt: .now.addingTimeInterval(-31_000)
        ),
        ProfileCommentHistoryItem(
            id: "comment-6",
            showId: 93405,
            showTitle: "Squid Game",
            seasonNumber: 1,
            episodeNumber: 6,
            episodeTitle: "Gganbu",
            body: "The game mechanics are simple, which makes the emotional turn hit even harder.",
            netVotes: 53,
            createdAt: .now.addingTimeInterval(-52_000)
        ),
        ProfileCommentHistoryItem(
            id: "comment-7",
            showId: 110492,
            showTitle: "Peacemaker",
            seasonNumber: 1,
            episodeNumber: 8,
            episodeTitle: "It's Cow or Never",
            body: "The finale commits to the absurd tone without dropping the character work. That is harder than it looks.",
            netVotes: 26,
            createdAt: .now.addingTimeInterval(-86_400)
        ),
        ProfileCommentHistoryItem(
            id: "comment-8",
            showId: 76479,
            showTitle: "The Boys",
            seasonNumber: 3,
            episodeNumber: 6,
            episodeTitle: "Herogasm",
            body: "Wild episode, but the strongest scene is still the quiet confrontation afterward.",
            netVotes: 39,
            createdAt: .now.addingTimeInterval(-140_000)
        ),
        ProfileCommentHistoryItem(
            id: "comment-9",
            showId: 1399,
            showTitle: "The Last Kingdom",
            seasonNumber: 3,
            episodeNumber: 10,
            episodeTitle: "Finale",
            body: "The season earns this ending because every alliance has a real cost by the time we get here.",
            netVotes: 21,
            createdAt: .now.addingTimeInterval(-250_000)
        ),
        ProfileCommentHistoryItem(
            id: "comment-10",
            showId: 95396,
            showTitle: "Severance",
            seasonNumber: 1,
            episodeNumber: 7,
            episodeTitle: "Defiant Jazz",
            body: "The dance scene is unsettling because the office treats joy like another control system.",
            netVotes: 72,
            createdAt: .now.addingTimeInterval(-430_000)
        )
    ]
}
