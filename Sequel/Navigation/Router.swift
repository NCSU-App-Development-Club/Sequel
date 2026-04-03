import SwiftUI

@Observable
final class Router {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var watchlistPath = NavigationPath()
    var profilePath = NavigationPath()
    var presentedSheet: Sheet?

    func navigate(to route: Route, tab: AppTab = .home) {
        switch tab {
        case .home: homePath.append(route)
        case .watchlist: watchlistPath.append(route)
        case .profile: profilePath.append(route)
        case .search: break
        }
    }

    func pop(tab: AppTab = .home) {
        switch tab {
        case .home: guard !homePath.isEmpty else { return }; homePath.removeLast()
        case .watchlist: guard !watchlistPath.isEmpty else { return }; watchlistPath.removeLast()
        case .profile: guard !profilePath.isEmpty else { return }; profilePath.removeLast()
        case .search: break
        }
    }

    func popToRoot(tab: AppTab = .home) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .watchlist: watchlistPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        case .search: break
        }
    }

    func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismiss() {
        presentedSheet = nil
    }
}

enum AppTab: Sendable, Hashable {
    case home
    case watchlist
    case profile
    case search
}
