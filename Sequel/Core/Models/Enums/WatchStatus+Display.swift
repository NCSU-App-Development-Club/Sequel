import Foundation

extension WatchStatus {
    var displayName: String {
        switch self {
        case .watching: "Currently Watching"
        case .planToWatch: "Plan to Watch"
        case .completed: "Completed"
        }
    }

    var myShowsLabel: String {
        switch self {
        case .watching: "Watching"
        case .planToWatch: "Up Next"
        case .completed: "Completed"
        }
    }

    var myShowsIcon: String {
        switch self {
        case .watching: "eye"
        case .planToWatch: "tv"
        case .completed: "checkmark.square"
        }
    }
}

extension ShowListSortMode {
    var displayName: String {
        switch self {
        case .recentActivity: "Recent Activity"
        case .alphabetical: "Alphabetical"
        case .nextAiring: "Next Airing"
        }
    }
}
