# CLAUDE.md — ShowThread iOS Development Guide

## Tech Stack
- **Swift 6.2** with Approachable Concurrency enabled (MainActor default isolation)
- **SwiftUI** targeting iOS 26+ (Xcode 26+)
- **SwiftData** for local persistence
- **Firebase** (Auth, Firestore, Cloud Functions, FCM)
- **TMDB API v3** for content data
- **Kingfisher** for image caching
- **Liquid Glass** for navigation-layer UI

## Swift 6.2 Concurrency Rules

**MainActor is the default.** New Xcode 26 projects isolate all code to `@MainActor` unless marked `nonisolated` or `@concurrent`. This means:

```swift
// This is implicitly @MainActor — no annotation needed
class ShowViewModel { ... }

// Explicitly opt OUT for background work
nonisolated func parseJSON(_ data: Data) -> Show { ... }

// Use @concurrent for truly parallel work
@concurrent func fetchFromTMDB() async throws -> ShowDTO { ... }
```

**Key rules:**
- App target: MainActor default. SPM packages: nonisolated default. Be aware of this split.
- `nonisolated async` functions run on the **caller's actor** (not a background thread) — this is new in 6.2.
- Use `@concurrent` when you explicitly want background execution.
- All model types crossing isolation boundaries must conform to `Sendable`.
- Use actor-isolated protocol conformances: `class Foo: @MainActor Decodable { ... }`.

## SwiftUI Patterns

### ViewModels
```swift
@Observable
final class ShowDetailViewModel {
    private(set) var show: Show?
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let tmdbService: TMDBServiceProtocol

    init(tmdbService: TMDBServiceProtocol = TMDBService.shared) {
        self.tmdbService = tmdbService
    }

    func loadShow(id: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            show = try await tmdbService.fetchShow(id: id)
        } catch {
            self.error = .from(error)
        }
    }
}
```

**Rules:**
- Use `@Observable` (not `ObservableObject`/`@Published`) — it's the modern standard.
- Use `@State var viewModel = ViewModel()` in views (not `@StateObject`).
- Use `private(set)` on state properties — only the VM mutates state.
- Inject dependencies via protocols for testability.
- Use `.task { }` modifier to trigger async loads (auto-cancels on disappear).

### Navigation
```swift
@Observable
final class Router {
    var path = NavigationPath()
    var presentedSheet: Sheet?

    func navigate(to route: Route) { path.append(route) }
    func pop() { path.removeLast() }
    func popToRoot() { path.removeLast(path.count) }
}

enum Route: Hashable {
    case showDetail(tmdbId: Int)
    case episodeThread(showId: Int, season: Int, episode: Int)
}
```
Use `NavigationStack(path: $router.path)` with `.navigationDestination(for:)`. Supports deep links natively.

### State Management
```swift
enum LoadingState<T> {
    case idle, loading, loaded(T), error(AppError)
}

// In view:
switch viewModel.loadingState {
case .idle, .loading: ProgressView()
case .loaded(let data): ContentView(data: data)
case .error(let err): ErrorView(error: err, onRetry: { ... })
}
```

## SwiftData

```swift
@Model
final class Show {
    @Attribute(.unique) var tmdbId: Int
    var title: String
    @Relationship(deleteRule: .cascade) var seasons: [Season]
    // ...
}
```

**Rules:**
- SwiftData models are `@Observable` by default — they drive SwiftUI reactively.
- Use `@Query` in views for automatic fetching and updates.
- Use `modelContext.insert()` / `modelContext.delete()` / `try modelContext.save()`.
- Set up `ModelContainer` at app root and pass via `.modelContainer()`.
- For cache TTL, check `lastRefreshed` timestamps in your service layer, not in SwiftData itself.

## Liquid Glass

**Principle: glass is for chrome, not for content.**

```swift
// Navigation layer — USE glass
TabView { ... }                              // Auto glass in iOS 26
.buttonStyle(.glass)                         // Interactive glass buttons
.glassEffect()                               // Custom glass surfaces
.glassEffectID("sort", in: namespace)        // Coordinated morphing

// Content layer — DO NOT use glass
List { ... }                                 // Keep opaque
CommentCard(comment: comment)                // Keep opaque
```

**Where to apply glass:** tab bars, toolbars, floating buttons, sort controls, compose bars, streaming chips, season picker pills.

**Where NOT to apply glass:** list rows, comment cards, show cards, text-heavy content, full-screen backgrounds.

Gate all glass behind `#available(iOS 26.0, *)` as defensive practice.

## Firestore Patterns

```swift
// Real-time listener
let listener = db.collection("comments")
    .whereField("episodeId", isEqualTo: episodeId)
    .order(by: "createdAt")
    .addSnapshotListener { snapshot, error in
        // Update local state
    }

// DETACH on disappear — critical for memory
listener.remove()
```

**Rules:**
- Optimistic UI: update local state immediately, then write to Firestore.
- Use snapshot listeners only on the active screen. Detach on navigation away.
- Denormalize `commentCount` on episode docs for fast list rendering.
- Security rules enforce: user writes own data only, 1 vote per comment.

## TMDB API

```swift
// Batch with append_to_response (up to 20 sub-requests)
let url = "https://api.themoviedb.org/3/tv/\(id)?append_to_response=season/1,season/2,watch/providers"

// Image URLs
let posterURL = "https://image.tmdb.org/t/p/w342\(posterPath)"  // lists
let posterURL = "https://image.tmdb.org/t/p/w500\(posterPath)"  // detail
let backdropURL = "https://image.tmdb.org/t/p/w780\(backdropPath)" // hero
```

**Rules:**
- Debounce search at 300ms.
- Cache config endpoint for 24h, show metadata for 6h.
- Movies normalize to: Show → Season(1) → Episode(1).
- Handle >20 seasons with a second API call.

## Project Structure

```
ShowThread/
├── App/
│   └── ShowThreadApp.swift
├── Core/
│   ├── Models/          # Show, Season, Episode, Comment, Vote, etc.
│   ├── Services/        # TMDBService, AuthService, FirestoreService
│   ├── Networking/      # APIClient, endpoints, DTOs
│   └── DesignSystem/    # GlassTokens, colors, typography
├── Features/
│   ├── Home/            # HomeView, HomeViewModel
│   ├── MyShows/         # MyShowsView, WatchlistViewModel
│   ├── Profile/         # ProfileView, ProfileViewModel
│   ├── ShowDetail/      # ShowDetailView, ShowDetailViewModel
│   ├── EpisodeThread/   # ThreadView, ThreadViewModel, CommentRow
│   └── Auth/            # AuthView, AuthViewModel
├── Navigation/
│   ├── Router.swift
│   ├── Route.swift
│   └── DeepLinkHandler.swift
└── Utilities/
    ├── Extensions/
    └── Helpers/
```

## Sprint Execution Protocol

Each sprint follows this cycle:

1. **Read `app_spec.txt`** for the section you're implementing.
2. **Check `feature_list.json`** for the specific tests that cover your sprint.
3. **Build the feature** following patterns in this document.
4. **Test against the feature_list steps** — verify each step passes.
5. **Mark passing tests** by changing `"passes": false` to `"passes": true`.
6. **NEVER remove or edit features** in `feature_list.json` — only flip `passes`.
7. **Commit** with descriptive messages referencing test IDs.
8. **Update `claude-progress.txt`** before session ends.

## Common Pitfalls

- **Don't** use `ObservableObject` / `@Published` / `@StateObject` — use `@Observable` / `@State`.
- **Don't** use `NavigationView` — use `NavigationStack`.
- **Don't** forget to detach Firestore listeners on view disappear.
- **Don't** hardcode colors — use semantic system colors for dark mode.
- **Don't** apply `.glassEffect()` to content views — only chrome.
- **Don't** block the main actor with synchronous work — use `@concurrent` or `nonisolated`.
- **Don't** forget `Sendable` conformance on types crossing actor boundaries.
- **Do** use `.task { }` for async work in views (auto-cancels).
- **Do** use `LazyVStack` for long lists (not `VStack`).
- **Do** use `private(set)` on ViewModel state properties.
- **Do** gate iOS 26 APIs behind `#available`.