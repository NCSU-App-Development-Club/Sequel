import SwiftUI

@Observable
final class Router {
    var homePath = NavigationPath()
    var myShowsPath = NavigationPath()
    var profilePath = NavigationPath()
    var presentedSheet: Sheet?

    func navigate(to route: Route, tab: Tab = .home) {
        switch tab {
        case .home: homePath.append(route)
        case .myShows: myShowsPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    func pop(tab: Tab = .home) {
        switch tab {
        case .home: guard !homePath.isEmpty else { return }; homePath.removeLast()
        case .myShows: guard !myShowsPath.isEmpty else { return }; myShowsPath.removeLast()
        case .profile: guard !profilePath.isEmpty else { return }; profilePath.removeLast()
        }
    }

    func popToRoot(tab: Tab = .home) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .myShows: myShowsPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }

    func dismiss() {
        presentedSheet = nil
    }
}

enum Tab: Sendable {
    case home
    case myShows
    case profile
}
