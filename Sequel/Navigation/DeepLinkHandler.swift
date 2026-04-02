import Foundation

struct DeepLinkHandler {
    /// Parses `showthread://show/{tmdbId}/season/{n}/episode/{n}` and navigates
    static func handle(url: URL, router: Router) {
        guard url.scheme == "showthread" else { return }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        // Expected: ["show", "{id}", "season", "{n}", "episode", "{n}"]
        guard pathComponents.count >= 6,
              pathComponents[0] == "show",
              let tmdbId = Int(pathComponents[1]),
              pathComponents[2] == "season",
              let season = Int(pathComponents[3]),
              pathComponents[4] == "episode",
              let episode = Int(pathComponents[5])
        else {
            // Partial deep link: just go to show detail
            if let idStr = url.pathComponents.first(where: { Int($0) != nil }),
               let tmdbId = Int(idStr) {
                router.navigate(to: .showDetail(tmdbId: tmdbId), tab: .home)
            }
            return
        }

        router.navigate(to: .showDetail(tmdbId: tmdbId), tab: .home)
        router.navigate(to: .episodeThread(showId: tmdbId, season: season, episode: episode), tab: .home)
    }
}
