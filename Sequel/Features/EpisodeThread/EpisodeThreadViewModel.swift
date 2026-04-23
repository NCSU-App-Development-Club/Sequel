import Foundation
import SwiftData

@Observable
final class EpisodeThreadViewModel {
    private(set) var show: Show?
    private(set) var episode: Episode?
    private(set) var streamingLinks: [StreamingLink] = []
    private(set) var isLoading = false
    private(set) var error: AppError?
    var isOverviewExpanded = false
    var isStreamingExpanded = false

    // MARK: - Comment State
    private(set) var comments: [Comment] = []
    var selectedSortMode: CommentSortMode = .hot
    var composeText: String = ""

    /// Tracks the current user's vote per comment. Key = comment ID, value = up or down.
    /// When nil (no entry), the user hasn't voted on that comment.
    private(set) var userVotes: [String: VoteValue] = [:]

    /// The comment the user is currently replying to, or nil for a top-level comment.
    var replyingTo: Comment?

    /// Returns comments sorted by the selected mode while keeping reply subtrees
    /// directly under their parent comment.
    var sortedComments: [Comment] {
        let commentIDs = Set(comments.map(\.id))
        let commentsByParent = Dictionary(grouping: comments, by: \.parentCommentId)
        let topLevelComments = comments.filter { comment in
            guard let parentCommentId = comment.parentCommentId else { return true }
            return !commentIDs.contains(parentCommentId)
        }

        var flattenedComments: [Comment] = []
        var visitedCommentIDs = Set<String>()

        func appendThread(startingWith comment: Comment) {
            guard visitedCommentIDs.insert(comment.id).inserted else { return }
            flattenedComments.append(comment)

            let replies = sortedForCurrentMode(commentsByParent[Optional(comment.id)] ?? [])
            for reply in replies {
                appendThread(startingWith: reply)
            }
        }

        for comment in sortedForCurrentMode(topLevelComments) {
            appendThread(startingWith: comment)
        }

        let remainingComments = comments.filter { !visitedCommentIDs.contains($0.id) }
        for comment in sortedForCurrentMode(remainingComments) {
            appendThread(startingWith: comment)
        }

        return flattenedComments
    }

    private func sortedForCurrentMode(_ comments: [Comment]) -> [Comment] {
        comments.sorted { lhs, rhs in
            if lhs.id == rhs.id { return false }

            switch selectedSortMode {
            case .hot:
                // "Hot" weighs recent + high score — simplified here as score descending.
                if lhs.netScore != rhs.netScore { return lhs.netScore > rhs.netScore }
            case .top:
                if lhs.netScore != rhs.netScore { return lhs.netScore > rhs.netScore }
            case .new:
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            case .controversial:
                // Controversial = lots of votes on both sides (high total, low net).
                let lhsTotalVotes = lhs.upvoteCount + lhs.downvoteCount
                let rhsTotalVotes = rhs.upvoteCount + rhs.downvoteCount
                if lhsTotalVotes != rhsTotalVotes { return lhsTotalVotes > rhsTotalVotes }

                let lhsNetDistance = abs(lhs.netScore)
                let rhsNetDistance = abs(rhs.netScore)
                if lhsNetDistance != rhsNetDistance { return lhsNetDistance < rhsNetDistance }
            }

            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.id < rhs.id
        }
    }

    private let tmdbService: TMDBServiceProtocol
    private let cacheService = TMDBCacheService.shared

    init(tmdbService: TMDBServiceProtocol = TMDBService.shared) {
        self.tmdbService = tmdbService
    }

    func loadEpisode(showId: Int, season: Int, episodeNumber: Int, context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        // Load show from cache
        show = cacheService.fetchCachedShowIgnoringTTL(tmdbId: showId, context: context)

        // Load episode from cache
        let episodes = cacheService.fetchCachedEpisodes(
            showTmdbId: showId,
            seasonNumber: season,
            context: context
        )
        episode = episodes.first(where: { $0.episodeNumber == episodeNumber })

        // If no cached episode, fetch the season
        if episode == nil {
            do {
                let seasonDTO = try await tmdbService.fetchSeason(showId: showId, seasonNumber: season)
                let episodeModels = (seasonDTO.episodes ?? []).map {
                    Episode(from: $0, showTmdbId: showId, seasonNumber: season)
                }

                // Cache
                let cachedSeasons = cacheService.fetchCachedSeasons(showTmdbId: showId, context: context)
                if let cachedSeason = cachedSeasons.first(where: { $0.seasonNumber == season }) {
                    cacheService.cacheEpisodes(episodeModels, for: cachedSeason, context: context)
                }

                episode = episodeModels.first(where: { $0.episodeNumber == episodeNumber })
            } catch {
                self.error = .from(error)
            }
        }

        // Load streaming links
        if let show = show {
            await loadStreamingLinks(showId: show.tmdbId)
        }

        // Load hardcoded comments for the UI demo
        comments = Self.sampleComments(for: "\(showId)-s\(season)e\(episodeNumber)")
    }

    // MARK: - Comment Actions (local-only)

    /// Toggles a vote on a comment. Three states:
    /// 1. No vote → applies the vote (adds 1 to upvote or downvote count)
    /// 2. Same vote again → removes the vote (subtracts 1)
    /// 3. Opposite vote → switches (removes old, applies new)
    func toggleVote(commentId: String, direction: VoteValue) {
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }

        let currentVote = userVotes[commentId]

        if currentVote == direction {
            // Tapping the same arrow again → undo the vote
            userVotes[commentId] = nil
            if direction == .up {
                comments[index].upvoteCount -= 1
            } else {
                comments[index].downvoteCount -= 1
            }
        } else {
            // If switching from the opposite vote, undo that first
            if let oldVote = currentVote {
                if oldVote == .up {
                    comments[index].upvoteCount -= 1
                } else {
                    comments[index].downvoteCount -= 1
                }
            }
            // Apply the new vote
            userVotes[commentId] = direction
            if direction == .up {
                comments[index].upvoteCount += 1
            } else {
                comments[index].downvoteCount += 1
            }
        }
    }

    /// Sets the compose bar to reply mode for a specific comment.
    func startReply(to comment: Comment) {
        replyingTo = comment
    }

    /// Cancels reply mode, going back to top-level compose.
    func cancelReply() {
        replyingTo = nil
    }

    /// "Sends" a comment by appending it to the local array.
    /// If `replyingTo` is set, creates a nested reply under that comment.
    func sendComment() {
        guard !composeText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let parentId = replyingTo?.id
        let depth = replyingTo != nil ? min((replyingTo?.depth ?? 0) + 1, GlassTokens.CommentIndent.maxDepth) : 0

        let newComment = Comment(
            id: UUID().uuidString,
            authorId: "current-user",
            authorDisplayName: "you",
            authorAvatarURL: nil,
            authorKarma: 0,
            episodeId: "demo",
            parentCommentId: parentId,
            body: composeText,
            upvoteCount: 1,
            downvoteCount: 0,
            createdAt: .now,
            editedAt: nil,
            isDeleted: false,
            depth: depth
        )

        if let parentId = parentId,
           let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
            // Insert the reply right after its parent comment
            comments.insert(newComment, at: parentIndex + 1)
        } else {
            // Top-level comment goes to the top
            comments.insert(newComment, at: 0)
        }

        composeText = ""
        replyingTo = nil
    }

    private func loadStreamingLinks(showId: Int) async {
        do {
            let response = try await tmdbService.fetchWatchProviders(showId: showId)
            let region = Locale.current.region?.identifier ?? "US"
            if let countryProviders = response.results?[region] {
                streamingLinks = StreamingLink.from(providers: countryProviders)
            }
        } catch {
            streamingLinks = []
        }
    }

    // MARK: - Hardcoded Sample Data

    /// Generates a realistic set of fake comments that look like the design mockup.
    /// Every episode gets the same set — this is just for UI development.
    static func sampleComments(for episodeId: String) -> [Comment] {
        let now = Date.now
        return [
            Comment(
                id: "c1", authorId: "u1", authorDisplayName: "tvfanatic42",
                authorAvatarURL: nil, authorKarma: 156, episodeId: episodeId,
                parentCommentId: nil,
                body: "This episode completely blew my mind. The reveal at the end was something I did NOT see coming. The writing this season has been on another level.",
                upvoteCount: 84, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-1200), editedAt: nil,
                isDeleted: false, depth: 0
            ),
            Comment(
                id: "c2", authorId: "u2", authorDisplayName: "showrunner_fan",
                authorAvatarURL: nil, authorKarma: 89, episodeId: episodeId,
                parentCommentId: "c1",
                body: "Right?! I had to rewatch the last 10 minutes twice. The foreshadowing from episode 2 finally makes sense now.",
                upvoteCount: 44, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-900), editedAt: nil,
                isDeleted: false, depth: 1
            ),
            Comment(
                id: "c3", authorId: "u3", authorDisplayName: "detail_spotter",
                authorAvatarURL: nil, authorKarma: 234, episodeId: episodeId,
                parentCommentId: "c1",
                body: "If you look closely at the background in scene 5, there's actually a clue hidden in the set design. The production team is insane.",
                upvoteCount: 32, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-600), editedAt: nil,
                isDeleted: false, depth: 1
            ),
            Comment(
                id: "c4", authorId: "u4", authorDisplayName: "casual_viewer",
                authorAvatarURL: nil, authorKarma: 12, episodeId: episodeId,
                parentCommentId: nil,
                body: "I'm confused about the timeline though. Can someone explain how the flashback connects to the present?",
                upvoteCount: 18, downvoteCount: 3,
                createdAt: now.addingTimeInterval(-1800), editedAt: nil,
                isDeleted: false, depth: 0
            ),
            Comment(
                id: "c5", authorId: "u5", authorDisplayName: "theory_crafter",
                authorAvatarURL: nil, authorKarma: 312, episodeId: episodeId,
                parentCommentId: nil,
                body: "[spoiler] I think the character we saw at the end is actually the same person from the pilot episode. The scar on their hand matches perfectly.",
                upvoteCount: 109, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-3600), editedAt: nil,
                isDeleted: false, depth: 0
            ),
            Comment(
                id: "c6", authorId: "u6", authorDisplayName: "debunker99",
                authorAvatarURL: nil, authorKarma: 45, episodeId: episodeId,
                parentCommentId: "c5",
                body: "Interesting theory but I think you're reaching too much into the scar thing. The showrunner confirmed in an interview that was a continuity error.",
                upvoteCount: 29, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-2400), editedAt: nil,
                isDeleted: false, depth: 1
            ),
            Comment(
                id: "c7", authorId: "u7", authorDisplayName: "cinematography_nerd",
                authorAvatarURL: nil, authorKarma: 178, episodeId: episodeId,
                parentCommentId: nil,
                body: "Can we talk about that one-take tracking shot through the entire building? That must have taken dozens of takes to get right. This show's production value is movie-level.",
                upvoteCount: 201, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-4800), editedAt: nil,
                isDeleted: false, depth: 0
            ),
            Comment(
                id: "c8", authorId: "u8", authorDisplayName: "first_timer",
                authorAvatarURL: nil, authorKarma: 3, episodeId: episodeId,
                parentCommentId: nil,
                body: "Just started watching this show yesterday and binged all the way to here. Absolutely hooked. Where has this been all my life?",
                upvoteCount: 58, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-7200), editedAt: nil,
                isDeleted: false, depth: 0
            ),
            Comment(
                id: "c9", authorId: "u9", authorDisplayName: "og_watcher",
                authorAvatarURL: nil, authorKarma: 567, episodeId: episodeId,
                parentCommentId: "c8",
                body: "Welcome to the club! Avoid the subreddit though, spoilers everywhere. This thread is much safer.",
                upvoteCount: 34, downvoteCount: 0,
                createdAt: now.addingTimeInterval(-5400), editedAt: nil,
                isDeleted: false, depth: 1
            ),
        ]
    }
}
