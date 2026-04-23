import Foundation

@Observable
final class MyShowsViewModel {
    var selectedStatus: WatchStatus = .watching
    var sortMode: ShowListSortMode = .recentActivity

    func rows(
        entries: [WatchlistEntry],
        shows: [Show],
        episodes: [Episode]
    ) -> [MyShowRowModel] {
        let activeEntries = entries
            .filter { $0.userId == "local_user" && $0.status == selectedStatus }

        let showsByID = Dictionary(uniqueKeysWithValues: shows.map { ($0.tmdbId, $0) })
        let episodesByShow = Dictionary(grouping: episodes, by: \.showTmdbId)

        let mappedRows = activeEntries.compactMap { entry -> MyShowRowModel? in
            guard let show = entry.show ?? showsByID[entry.tmdbId] else { return nil }
            let showEpisodes = sortEpisodes(episodesByShow[show.tmdbId] ?? [])

            let upcomingEpisode = showEpisodes
                .filter { episode in
                    guard let airDate = episode.airDate else { return false }
                    return airDate > .now
                }
                .min { lhs, rhs in
                    guard let left = lhs.airDate, let right = rhs.airDate else { return false }
                    return left < right
                }
            let discussedEpisodes = showEpisodes.filter { $0.commentCount > 0 }
            let discussedCount = discussedEpisodes.count
            let loadedEpisodeCount = showEpisodes.count

            let nextEpisodeText: String?
            if let upcomingEpisode, let airDate = upcomingEpisode.airDate {
                nextEpisodeText = "New episode \(nextEpisodeLabel(for: airDate))"
            } else {
                nextEpisodeText = nil
            }
            let progressText = loadedEpisodeCount > 0
                ? "\(discussedCount) of \(loadedEpisodeCount) episodes discussed"
                : nil

            let latestActivityDate = showEpisodes.compactMap(\.airDate).max()
                ?? entry.dateAdded

            return MyShowRowModel(
                id: entry.id,
                tmdbId: show.tmdbId,
                mediaType: show.mediaType,
                status: entry.status,
                title: show.title,
                posterPath: show.posterPath,
                backdropPath: show.backdropPath,
                metadataLine: metadataLine(for: show),
                genres: Array(show.genres.prefix(2)),
                nextEpisodeText: nextEpisodeText,
                progressText: progressText,
                unreadBadgeCount: min(discussedCount, 9),
                notificationsEnabled: entry.notificationsEnabled,
                latestActivityDate: latestActivityDate,
                nextAirDate: upcomingEpisode?.airDate
            )
        }

        return mappedRows.sorted(by: sortComparator)
    }

    func countLabel(for rows: [MyShowRowModel]) -> String {
        let count = rows.count
        return count == 1 ? "1 show" : "\(count) shows"
    }

    func emptyStateTitle(totalSavedShows: Int) -> String {
        if totalSavedShows == 0 {
            return "Your watchlist is empty"
        }
        return "No \(selectedStatus.myShowsLabel.lowercased()) shows yet"
    }

    func emptyStateMessage(totalSavedShows: Int) -> String {
        if totalSavedShows == 0 {
            return "Use the plus button to start building your list."
        }
        return "Move a show into \(selectedStatus.myShowsLabel) or add a new one."
    }

    private func metadataLine(for show: Show) -> String {
        let provider = show.networks.first ?? fallbackProvider(for: show)
        return provider
    }

    private func fallbackProvider(for show: Show) -> String {
        if let genre = show.genres.first {
            return genre
        }
        return show.mediaType == .movie ? "Film" : "Series"
    }

    private func nextEpisodeLabel(for airDate: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfAirDate = calendar.startOfDay(for: airDate)
        let daysUntilAiring = calendar.dateComponents([.day], from: startOfToday, to: startOfAirDate).day ?? 0

        switch daysUntilAiring {
        case 0:
            return "today"
        case 1:
            return "tomorrow"
        case let count where count > 1:
            return "in \(count) days"
        default:
            return airDate.relativeString.lowercased()
        }
    }

    private func sortEpisodes(_ episodes: [Episode]) -> [Episode] {
        episodes.sorted { lhs, rhs in
            switch (lhs.airDate, rhs.airDate) {
            case let (left?, right?):
                if left != right {
                    return left > right
                }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }

            if lhs.seasonNumber != rhs.seasonNumber {
                return lhs.seasonNumber > rhs.seasonNumber
            }

            return lhs.episodeNumber > rhs.episodeNumber
        }
    }

    private func sortComparator(lhs: MyShowRowModel, rhs: MyShowRowModel) -> Bool {
        switch sortMode {
        case .recentActivity:
            return lhs.latestActivityDate > rhs.latestActivityDate
        case .alphabetical:
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        case .nextAiring:
            switch (lhs.nextAirDate, rhs.nextAirDate) {
            case let (left?, right?):
                return left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }
}

struct MyShowRowModel: Identifiable {
    let id: String
    let tmdbId: Int
    let mediaType: MediaType
    let status: WatchStatus
    let title: String
    let posterPath: String?
    let backdropPath: String?
    let metadataLine: String
    let genres: [String]
    let nextEpisodeText: String?
    let progressText: String?
    let unreadBadgeCount: Int
    let notificationsEnabled: Bool
    let latestActivityDate: Date
    let nextAirDate: Date?
}
