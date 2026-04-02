import SwiftUI
import SwiftData

@main
struct ShowThreadApp: App {
    @State private var router = Router()

    init() {
        KingfisherConfig.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Show.self,
            Season.self,
            Episode.self,
            WatchlistEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    DeepLinkHandler.handle(url: url, router: router)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
