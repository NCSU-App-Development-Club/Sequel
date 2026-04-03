import SwiftUI

struct ContentView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack(path: $router.homePath) {
                    HomeView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }
            Tab("My Shows", systemImage: "rectangle.stack.fill") {
                NavigationStack(path: $router.myShowsPath) {
                    MyShowsView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }
            Tab("Profile", systemImage: "person.fill") {
                NavigationStack(path: $router.profilePath) {
                    ProfileView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }
            Tab(role: .search) {
                NavigationStack {
                    SearchView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .showDetail(let tmdbId, let mediaType):
            ShowDetailView(tmdbId: tmdbId, mediaType: mediaType)
        case .episodeThread(let showId, let season, let episode):
            ThreadView(showId: showId, season: season, episode: episode)
        case .search:
            SearchView()
        case .settings:
            Text("Settings")
        case .notifications:
            Text("Notifications")
        case .commentHistory:
            Text("Comment History")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .statusPicker:
            Text("Status Picker")
        case .compose:
            Text("Compose")
        case .addShow:
            Text("Add Show")
        }#imageLiteral(resourceName: "simulator_screenshot_CBFC0D8B-46A5-4C2E-BBD5-FF98DD1D67D0.png")
    }
}
