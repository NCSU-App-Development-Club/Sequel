# ShowThread Foundation Sprint (Weeks 1-2) - Implementation Plan

## Current State Analysis

The repo contains an Xcode 26 project called **Sequel** with:
- `Sequel.xcodeproj` using `PBXFileSystemSynchronizedRootGroup` (Xcode 26's automatic file sync — no manual pbxproj edits needed for new files under `Sequel/`)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` already enabled
- `SWIFT_VERSION = 5.0` (needs update to 6.0 for full strict concurrency; see note below)
- `GENERATE_INFOPLIST_FILE = YES` (auto-generated, no manual Info.plist yet)
- Deployment target: iOS 26.2
- Development team: configured locally in Xcode
- Bundle ID: jbduran.Sequel
- Two starter files: `SequelApp.swift` and `ContentView.swift`

### Critical Observations

1. **FileSystemSynchronizedRootGroup**: The pbxproj uses Xcode 26's file system sync. Any `.swift` file placed under `Sequel/` is automatically included in the build. No pbxproj edits needed for adding source files. This is the key enabler for an agent-based approach.

2. **No SPM dependencies yet**: The `packageProductDependencies` array is empty. Firebase and Kingfisher must be added. Since editing pbxproj XML for SPM is fragile, this step should ideally be done via `xcodebuild` or by manually writing the correct pbxproj entries. The plan provides the exact pbxproj modifications needed.

3. **No Info.plist file**: Using auto-generated. We need a manual `Info.plist` for the TMDB API key entry and any custom URL schemes.

4. **SWIFT_VERSION = 5.0**: Xcode 26 with approachable concurrency uses Swift 6.2 semantics despite the "5.0" setting. The `SWIFT_APPROACHABLE_CONCURRENCY` and `SWIFT_DEFAULT_ACTOR_ISOLATION` flags are the ones that matter. The `5.0` is Xcode's default language mode; full Swift 6 language mode would be `6.0`. Since the spec says "Swift 6.2" but also says "Approachable Concurrency," we keep language mode at 5.0 (which is how Xcode 26 ships new projects) — the concurrency flags already give us MainActor default isolation. Adding `SWIFT_STRICT_CONCURRENCY = complete` is needed for compile-time enforcement.

---

## Architecture Decisions

### Decision 1: Project Renaming (Sequel -> ShowThread)

The existing Xcode project is named "Sequel" with bundle ID `jbduran.Sequel`. The spec calls the app "ShowThread." Two options:

**Option A (Recommended): Rename the app directory and update the pbxproj.** The `Sequel/` folder gets renamed to `ShowThread/` and key pbxproj references updated. The product name stays as `$(TARGET_NAME)` which would still produce "Sequel.app" unless we also rename the target.

**Option B: Keep "Sequel" as the internal project name, set display name to "ShowThread."** Add `CFBundleDisplayName = ShowThread` to Info.plist. The Xcode project stays `Sequel.xcodeproj`, the source folder stays `Sequel/`, but the app name on the Home Screen is "ShowThread."

**Recommendation: Option B.** Renaming targets/pbxproj from an agent is error-prone. We keep the existing `Sequel/` directory structure, rename the app entry point struct to `ShowThreadApp` (with `@main`), and set the display name via Info.plist. All file paths in this plan use `Sequel/` as the source root. The directory structure INSIDE `Sequel/` follows the spec's `ShowThread/` layout (App/, Core/, Features/, etc.).

### Decision 2: SwiftData @Model + Codable + Sendable

SwiftData `@Model` classes have specific constraints:
- `@Model` already synthesizes `Observable` conformance (no `@Observable` needed on models)
- `@Model` classes are NOT automatically `Codable` — we must implement `Codable` manually via `init(from:)` and `encode(to:)`
- `@Model` classes are NOT `Sendable` — they are reference types tied to a ModelContext. Making them `@unchecked Sendable` is the pragmatic approach since SwiftData models are actor-bound anyway
- `@Model` classes must be `final class`, not `struct`
- The `@Attribute(.unique)` annotation handles uniqueness constraints

**Approach:** Each `@Model` type gets:
- Manual `Codable` conformance via a `CodingKeys` enum and explicit init/encode
- `@unchecked Sendable` conformance (SwiftData models are inherently main-actor-bound in our architecture)
- A companion `Identifiable` conformance (using the SwiftData-managed `id` or our custom unique ID)

### Decision 3: TMDBService — Actor vs MainActor Default

With MainActor default isolation, a plain `class TMDBService` is already `@MainActor`. But network calls should NOT run on the main actor.

**Approach:** Make `TMDBService` an explicit `actor` (which opts it out of MainActor default). Its methods are actor-isolated, meaning callers `await` them. URLSession async calls naturally suspend and resume on the actor's executor. This is correct — TMDB parsing and caching logic stays off the main thread.

```swift
actor TMDBService: TMDBServiceProtocol {
    // All methods are nonisolated from MainActor,
    // callers must await
    func fetchShow(id: Int) async throws -> ShowDTO { ... }
}
```

The protocol `TMDBServiceProtocol` should be marked as `@MainActor`-independent. Since protocols in app target default to `@MainActor`, we need `nonisolated` on protocol methods, OR we make the protocol itself non-isolated. The cleanest approach:

```swift
protocol TMDBServiceProtocol: Sendable {
    func searchMulti(query: String) async throws -> [SearchResultDTO]
    func fetchShow(id: Int) async throws -> ShowDTO
    // ...
}
```

Since the protocol is in the app target (MainActor default), its methods are implicitly `@MainActor`. But an `actor` conforming to it would cause an isolation mismatch. **Solution:** Declare the protocol in a way that the methods are explicitly `nonisolated`:

```swift
nonisolated protocol TMDBServiceProtocol: Sendable {
    func searchMulti(query: String) async throws -> [SearchResultDTO]
    // ...
}
```

Or use `@concurrent` on protocol methods. The `nonisolated protocol` syntax is the cleanest in Swift 6.2.

### Decision 4: DTO-to-Model Mapping

**Approach:** Static factory methods on the `@Model` types themselves:
```swift
extension Show {
    convenience init(from dto: ShowDTO) { ... }
}
```

This keeps mapping logic colocated with the model and avoids a separate mapper class. DTOs live in `Core/Networking/DTOs/` and are pure `Codable` + `Sendable` structs with no SwiftData dependency.

### Decision 5: SPM Dependencies via pbxproj

Adding SPM packages requires editing the pbxproj to add `XCRemoteSwiftPackageReference` and `XCSwiftPackageProductDependency` entries. This is the most fragile part of the plan. The alternative is a `Package.resolved` approach, but Xcode manages that automatically.

**Approach:** Provide the exact pbxproj insertions needed. The agent must:
1. Add `XCRemoteSwiftPackageReference` entries for firebase-ios-sdk and Kingfisher
2. Add `XCSwiftPackageProductDependency` entries for each Firebase product + Kingfisher
3. Link them in the target's `packageProductDependencies`

---

## Implementation Plan — Ordered Steps

### Phase 0: Project Configuration (2 files + pbxproj edits)

#### Step 0.1: Add Info.plist

**File:** `Sequel/Info.plist`

Create a manual Info.plist with:
- `CFBundleDisplayName` = "ShowThread"
- `TMDB_API_KEY` = `$(TMDB_API_KEY)` (resolved from xcconfig or environment)
- `CFBundleURLTypes` for `showthread://` deep link scheme
- Keep all the auto-generated keys that Xcode expects

Then update pbxproj target build settings to add:
- `INFOPLIST_FILE = Sequel/Info.plist`
- Remove `GENERATE_INFOPLIST_FILE = YES` (or set to NO)
- Keep `INFOPLIST_KEY_*` settings for scene manifest, launch screen, etc.

Alternatively (simpler): Keep `GENERATE_INFOPLIST_FILE = YES` and add ONLY custom keys via `INFOPLIST_KEY_` build settings. For the TMDB API key, use a runtime `Bundle.main.infoDictionary` lookup with the key added via an xcconfig file.

**Recommended simpler approach:** Create an `.xcconfig` file for secrets and reference it from the project. But since this is foundation sprint, we can start with a simple constant file that reads from `Bundle.main`:

**File:** `Sequel/Core/Networking/APIConfig.swift`
- Reads `TMDB_API_KEY` from Info.plist / environment
- Provides base URLs as static constants
- No hardcoded keys

For now, since we have `GENERATE_INFOPLIST_FILE = YES`, we add custom Info.plist keys via build settings in pbxproj. But for the TMDB key specifically, the cleanest agent-writable approach is:

1. Create `Sequel/Info.plist` with all needed keys
2. Update pbxproj to point to it

#### Step 0.2: Add SPM Dependencies to pbxproj

**File:** `Sequel.xcodeproj/project.pbxproj`

Add the following package references and product dependencies. This requires inserting several sections into the pbxproj:

**Packages:**
- `https://github.com/firebase/firebase-ios-sdk` (exact version: 11.12.0 or latest stable)
- `https://github.com/onevcat/Kingfisher` (exact version: 8.3.2 or latest stable)

**Products to link:**
- FirebaseAuth
- FirebaseFirestore  
- FirebaseFunctions
- FirebaseMessaging
- FirebaseAnalytics
- FirebaseCrashlytics
- Kingfisher

The pbxproj edits require adding:
1. `XCRemoteSwiftPackageReference` section entries (2 packages)
2. `XCSwiftPackageProductDependency` section entries (7 products)
3. References in the target's `packageProductDependencies` array
4. Framework references in `PBXFrameworksBuildPhase`

**NOTE:** This is the highest-risk step for an agent. The pbxproj format is XML-like but with specific UUID conventions. Each reference needs a unique 24-character hex ID. The agent should generate these deterministically.

#### Step 0.3: Add Strict Concurrency + Swift Version build settings

**File:** `Sequel.xcodeproj/project.pbxproj`

Add to BOTH Debug and Release target-level build configs:
```
SWIFT_STRICT_CONCURRENCY = complete;
```

The `SWIFT_VERSION = 5.0` can stay — Xcode 26 with `SWIFT_APPROACHABLE_CONCURRENCY = YES` already enables Swift 6.2 concurrency semantics in language-mode 5.

---

### Phase 1: Directory Structure + Design System (5 files)

#### Step 1.1: Create Directory Skeleton

Create all directories by placing placeholder or real files in them. Since Xcode 26 uses FileSystemSynchronizedRootGroup, directories are auto-synced.

Directories to create (by placing files):
```
Sequel/App/
Sequel/Core/Models/
Sequel/Core/Models/Enums/
Sequel/Core/Services/
Sequel/Core/Networking/
Sequel/Core/Networking/DTOs/
Sequel/Core/DesignSystem/
Sequel/Features/Home/
Sequel/Features/MyShows/
Sequel/Features/Profile/
Sequel/Features/ShowDetail/
Sequel/Features/EpisodeThread/
Sequel/Features/Auth/
Sequel/Navigation/
Sequel/Utilities/Extensions/
Sequel/Utilities/Helpers/
```

#### Step 1.2: Design System — GlassTokens

**File:** `Sequel/Core/DesignSystem/GlassTokens.swift`

```swift
import SwiftUI

enum GlassTokens {
    // Corner Radii
    static let cornerRadiusSmall: CGFloat = 8    // comments
    static let cornerRadiusMedium: CGFloat = 12  // show cards
    static let cornerRadiusLarge: CGFloat = 16   // sheets
    static let cornerRadiusXL: CGFloat = 24      // floating elements

    // Padding
    static let paddingHorizontal: CGFloat = 16
    static let paddingVertical: CGFloat = 12
    static let paddingCompact: CGFloat = 8
    static let paddingLarge: CGFloat = 24

    // Stroke
    static let strokeThin: CGFloat = 0.5
    static let strokeRegular: CGFloat = 1.0

    // Comment Threading
    static let commentIndent: CGFloat = 16       // per level
    static let maxCommentIndent: CGFloat = 80    // 5 levels

    // Avatars
    static let avatarSizeInline: CGFloat = 24
    static let avatarSizeDetail: CGFloat = 40
    static let avatarSizeProfile: CGFloat = 80

    // Touch Targets
    static let minTouchTarget: CGFloat = 44
}
```

#### Step 1.3: Design System — AppColors

**File:** `Sequel/Core/DesignSystem/AppColors.swift`

```swift
import SwiftUI

enum AppColors {
    static let accent = Color(hex: 0x6C5CE7)       // warm indigo
    static let accentLight = Color(hex: 0x8B7CF7)
    static let accentDark = Color(hex: 0x5A4BD1)

    // Semantic
    static let upvote = Color.orange
    static let downvote = Color(hex: 0x6C7CE7)
    static let destructive = Color.red

    // Surfaces (use system colors for auto dark mode)
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemGroupedBackground)
    static let tertiaryBackground = Color(.tertiarySystemGroupedBackground)

    // Text
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
```

#### Step 1.4: Design System — AppTypography

**File:** `Sequel/Core/DesignSystem/AppTypography.swift`

```swift
import SwiftUI

enum AppTypography {
    static let showTitle: Font = .title2.bold()
    static let episodeTitle: Font = .headline
    static let commentBody: Font = .body
    static let metadata: Font = .caption.weight(.medium)
    static let sectionHeader: Font = .title3.bold()
    static let tabLabel: Font = .caption2
    static let buttonLabel: Font = .body.weight(.semibold)
    static let largeTitle: Font = .largeTitle.bold()
}
```

#### Step 1.5: Update AccentColor.colorset

**File:** `Sequel/Assets.xcassets/AccentColor.colorset/Contents.json`

Update to set the warm indigo #6C5CE7 as the accent color:
```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.424",
          "green": "0.361",
          "blue": "0.906",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

---

### Phase 2: Enums and Core Types (3 files)

#### Step 2.1: Model Enums

**File:** `Sequel/Core/Models/Enums/ShowEnums.swift`

All enum types used by models:
- `ShowStatus`: `.airing`, `.ended`, `.upcoming`, `.cancelled` — String raw value, Codable, Sendable
- `MediaType`: `.tvShow`, `.movie` — String raw value, Codable, Sendable
- `WatchStatus`: `.watching`, `.planToWatch`, `.completed` — String raw value, Codable, Sendable
- `StreamingType`: `.flatrate`, `.rent`, `.buy` — String raw value, Codable, Sendable

**File:** `Sequel/Core/Models/Enums/SortEnums.swift`

- `CommentSortMode`: `.hot`, `.top`, `.new`, `.controversial` — String, CaseIterable, Codable, Sendable
- `TopTimeFilter`: `.today`, `.thisWeek`, `.allTime` — String, CaseIterable, Codable, Sendable
- `ShowListSortMode`: `.recentActivity`, `.alphabetical`, `.nextAiring` — String, CaseIterable, Codable, Sendable

**File:** `Sequel/Core/Models/Enums/NotificationEnums.swift`

- `NotificationType`: `.reply`, `.newEpisode`, `.trending`, `.karmaMilestone` — String, Codable, Sendable
- `VoteValue`: `.up`, `.down` with `Int` raw values (+1, -1) — Codable, Sendable

---

### Phase 3: Data Models (8 files)

#### Step 3.1: SwiftData Models

**File:** `Sequel/Core/Models/Show.swift`

```swift
import Foundation
import SwiftData

@Model
final class Show: @unchecked Sendable {
    @Attribute(.unique) var tmdbId: Int
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var genres: [String]
    var networks: [String]
    var status: ShowStatus
    var firstAirDate: Date?
    var voteAverage: Double
    var mediaType: MediaType
    var seasonCount: Int
    var lastRefreshed: Date
    var followerCount: Int

    @Relationship(deleteRule: .cascade, inverse: \Season.show)
    var seasons: [Season]

    init(tmdbId: Int, title: String, overview: String, ...) { ... }
}

extension Show: Identifiable {
    var id: Int { tmdbId }
}
```

Note: `@Model` types store enums as their raw values automatically when the enum conforms to `Codable`. For `[String]` arrays, SwiftData handles them natively as transformable.

Manual `Codable` conformance via extension with `CodingKeys` and explicit `init(from decoder:)` / `encode(to encoder:)`. Use `@MainActor` isolated conformance since these are MainActor-bound:

```swift
extension Show: @MainActor Codable {
    enum CodingKeys: String, CodingKey { ... }
    convenience init(from decoder: Decoder) throws { ... }
    func encode(to encoder: Encoder) throws { ... }
}
```

**File:** `Sequel/Core/Models/Season.swift`

```swift
@Model
final class Season: @unchecked Sendable {
    @Attribute(.unique) var id: String  // "{tmdbId}_S{n}"
    var showTmdbId: Int
    var seasonNumber: Int
    var name: String
    var overview: String?
    var posterPath: String?
    var airDate: Date?
    var episodeCount: Int

    @Relationship(deleteRule: .cascade, inverse: \Episode.season)
    var episodes: [Episode]
    var show: Show?

    init(...) { ... }
}
```

**File:** `Sequel/Core/Models/Episode.swift`

```swift
@Model
final class Episode: @unchecked Sendable {
    @Attribute(.unique) var id: String  // "{tmdbId}_S{n}E{n}"
    var showTmdbId: Int
    var seasonNumber: Int
    var episodeNumber: Int
    var name: String
    var overview: String?
    var stillPath: String?
    var airDate: Date?
    var runtime: Int?
    var guestStars: [String]
    var commentCount: Int

    var season: Season?

    init(...) { ... }
}
```

**File:** `Sequel/Core/Models/WatchlistEntry.swift`

```swift
@Model
final class WatchlistEntry: @unchecked Sendable {
    @Attribute(.unique) var id: String  // "{userId}_{tmdbId}"
    var userId: String
    var tmdbId: Int
    var status: WatchStatus
    var dateAdded: Date
    var lastVisited: Date?
    var notificationsEnabled: Bool

    var show: Show?

    init(...) { ... }
}
```

#### Step 3.2: Firestore Struct Models

**File:** `Sequel/Core/Models/Comment.swift`

```swift
struct Comment: Identifiable, Codable, Sendable {
    let id: String
    let authorId: String
    var authorDisplayName: String
    var authorAvatarURL: String?
    var authorKarma: Int
    let episodeId: String
    let parentCommentId: String?
    var body: String
    var upvoteCount: Int
    var downvoteCount: Int
    let createdAt: Date
    var editedAt: Date?
    var isDeleted: Bool
    var depth: Int  // 0-5

    var netScore: Int { upvoteCount - downvoteCount }
}
```

**File:** `Sequel/Core/Models/Vote.swift`

```swift
struct Vote: Identifiable, Codable, Sendable {
    let id: String  // "{commentId}_{userId}"
    let commentId: String
    let userId: String
    let value: VoteValue
    let createdAt: Date
}
```

**File:** `Sequel/Core/Models/UserProfile.swift`

```swift
struct UserProfile: Identifiable, Codable, Sendable {
    let id: String  // Firebase UID
    var displayName: String
    var avatarURL: String?
    var bio: String?
    var karma: Int
    let joinedAt: Date
    var favoriteShowIds: [Int]
    var notificationPreferences: NotificationPrefs
}

struct NotificationPrefs: Codable, Sendable {
    var repliesEnabled: Bool
    var newEpisodesEnabled: Bool
    var trendingEnabled: Bool
    var karmaEnabled: Bool
    var quietHoursStart: Int?  // hour 0-23
    var quietHoursEnd: Int?
    var mutedShowIds: [Int]
}
```

**File:** `Sequel/Core/Models/AppNotification.swift` + `StreamingLink.swift`

`AppNotification`:
```swift
struct AppNotification: Identifiable, Codable, Sendable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    var showTmdbId: Int?
    var episodeId: String?
    var commentId: String?
    let createdAt: Date
    var isRead: Bool
}
```

`StreamingLink`:
```swift
struct StreamingLink: Identifiable, Codable, Sendable {
    let id: Int  // TMDB provider ID
    let providerName: String
    let logoPath: String
    let webURL: URL
    var universalLinkURL: URL?
    let type: StreamingType
}
```

---

### Phase 4: Error Handling + Utilities (3 files)

#### Step 4.1: AppError

**File:** `Sequel/Utilities/Helpers/AppError.swift`

```swift
enum AppError: Error, LocalizedError, Sendable {
    case networkError(underlying: String)
    case decodingError(underlying: String)
    case apiError(statusCode: Int, message: String)
    case authenticationRequired
    case notFound
    case rateLimited
    case serverError
    case unknown(String)

    var errorDescription: String? { ... }

    static func from(_ error: Error) -> AppError { ... }
}
```

#### Step 4.2: LoadingState

**File:** `Sequel/Utilities/Helpers/LoadingState.swift`

```swift
enum LoadingState<T>: Sendable where T: Sendable {
    case idle
    case loading
    case loaded(T)
    case error(AppError)
}
```

#### Step 4.3: Extensions

**File:** `Sequel/Utilities/Extensions/Date+Extensions.swift`

- `timeAgoDisplay()` for comment timestamps
- `isWithin(hours:)` for staleness checks

**File:** `Sequel/Utilities/Extensions/URL+TMDB.swift`

- Static helpers for constructing TMDB image URLs at various sizes
- `URL.tmdbPoster(_ path: String, size: TMDBImageSize) -> URL`
- `URL.tmdbBackdrop(_ path: String, size: TMDBImageSize) -> URL`

---

### Phase 5: Networking Layer — TMDB (5 files)

#### Step 5.1: API Configuration

**File:** `Sequel/Core/Networking/APIConfig.swift`

```swift
enum APIConfig {
    static let tmdbBaseURL = "https://api.themoviedb.org/3"
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p"

    static var tmdbAPIKey: String {
        guard let key = Bundle.main.infoDictionary?["TMDB_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("TMDB_API_KEY not found in Info.plist")
        }
        return key
    }

    // Image sizes
    enum PosterSize: String { case w342, w500 }
    enum BackdropSize: String { case w300, w780 }
    enum StillSize: String { case w300, w780 }
}
```

#### Step 5.2: TMDB DTOs

**File:** `Sequel/Core/Networking/DTOs/TMDBDTOs.swift`

All DTO structs — pure Codable + Sendable, matching TMDB JSON:
- `TMDBSearchResponse`, `TMDBSearchResult`
- `TMDBShowDTO` (tv detail response)
- `TMDBSeasonDTO`
- `TMDBEpisodeDTO`
- `TMDBMovieDTO`
- `TMDBWatchProvidersResponse`, `TMDBProviderDTO`
- `TMDBTrendingResponse`
- `TMDBConfigurationDTO`

Each uses `CodingKeys` with `snake_case` mapping. Use `JSONDecoder` with `.convertFromSnakeCase` key strategy globally.

#### Step 5.3: TMDBService Protocol

**File:** `Sequel/Core/Services/TMDBServiceProtocol.swift`

```swift
nonisolated protocol TMDBServiceProtocol: Sendable {
    func searchMulti(query: String) async throws -> [TMDBSearchResult]
    func fetchShow(id: Int) async throws -> TMDBShowDTO
    func fetchSeason(showId: Int, seasonNumber: Int) async throws -> TMDBSeasonDTO
    func fetchMovie(id: Int) async throws -> TMDBMovieDTO
    func fetchWatchProviders(showId: Int) async throws -> [TMDBProviderDTO]
    func fetchTrending() async throws -> [TMDBSearchResult]
    func fetchConfiguration() async throws -> TMDBConfigurationDTO
}
```

Mark as `nonisolated protocol` to opt out of MainActor default, since the actor conforming type has its own isolation.

#### Step 5.4: TMDBService Implementation

**File:** `Sequel/Core/Services/TMDBService.swift`

```swift
actor TMDBService: TMDBServiceProtocol {
    static let shared = TMDBService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private var configCache: (config: TMDBConfigurationDTO, fetchedAt: Date)?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .formatted(...)
    }

    func fetchShow(id: Int) async throws -> TMDBShowDTO {
        // Uses append_to_response for seasons + watch/providers
        let url = buildURL(path: "/tv/\(id)",
                          queryItems: [.init(name: "append_to_response",
                                            value: "watch/providers")])
        return try await request(url: url)
    }

    func fetchConfiguration() async throws -> TMDBConfigurationDTO {
        // 24h cache
        if let cached = configCache,
           Date().timeIntervalSince(cached.fetchedAt) < 86400 {
            return cached.config
        }
        let config: TMDBConfigurationDTO = try await request(
            url: buildURL(path: "/configuration")
        )
        configCache = (config, Date())
        return config
    }

    // Private helpers
    private func buildURL(path: String, queryItems: [URLQueryItem] = []) -> URL { ... }
    private func request<T: Decodable>(url: URL) async throws -> T { ... }
}
```

Key details:
- Error handling maps HTTP status codes to `AppError`
- 429 (rate limit) detection
- Response validation before decoding
- All methods are actor-isolated (no data races on cache)

#### Step 5.5: DTO-to-Model Mapping Extensions

**File:** `Sequel/Core/Networking/DTOs/DTOMappers.swift`

Convenience initializers on SwiftData models:
```swift
extension Show {
    convenience init(from dto: TMDBShowDTO) {
        self.init(
            tmdbId: dto.id,
            title: dto.name,
            overview: dto.overview,
            posterPath: dto.posterPath,
            ...
        )
    }
}

extension Season {
    convenience init(from dto: TMDBSeasonDTO, showTmdbId: Int) { ... }
}

extension Episode {
    convenience init(from dto: TMDBEpisodeDTO, showTmdbId: Int) { ... }
}
```

---

### Phase 6: Firebase Services (4 files)

#### Step 6.1: AuthService Protocol + Stub

**File:** `Sequel/Core/Services/AuthServiceProtocol.swift`

```swift
nonisolated protocol AuthServiceProtocol: Sendable {
    var currentUserId: String? { get async }
    var isAuthenticated: Bool { get async }
    func signInWithApple() async throws -> UserProfile
    func signInWithEmail(email: String, password: String) async throws -> UserProfile
    func signInWithGoogle() async throws -> UserProfile
    func signOut() async throws
    func deleteAccount() async throws
}
```

**File:** `Sequel/Core/Services/AuthService.swift`

```swift
@Observable
final class AuthService: AuthServiceProtocol {
    private(set) var currentUser: UserProfile?

    nonisolated var currentUserId: String? {
        // Will use Firebase Auth.auth().currentUser?.uid in real implementation
        nil
    }

    nonisolated var isAuthenticated: Bool {
        // Stub
        false
    }

    func signInWithApple() async throws -> UserProfile {
        // Stub — will implement with AuthenticationServices
        throw AppError.unknown("Not implemented")
    }

    func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        throw AppError.unknown("Not implemented")
    }

    func signInWithGoogle() async throws -> UserProfile {
        throw AppError.unknown("Not implemented")
    }

    func signOut() async throws {
        currentUser = nil
    }

    func deleteAccount() async throws {
        throw AppError.unknown("Not implemented")
    }
}
```

Note: `nonisolated` is needed on computed properties that don't access MainActor state, but `currentUser` being `@Observable` state IS MainActor. The stub can use `nonisolated` on the protocol requirements that just return nil. Real implementation will use Firebase Auth which is itself Sendable.

#### Step 6.2: FirestoreService Protocol + Implementation

**File:** `Sequel/Core/Services/FirestoreServiceProtocol.swift`

```swift
nonisolated protocol FirestoreServiceProtocol: Sendable {
    // User Profile
    func fetchUserProfile(userId: String) async throws -> UserProfile?
    func createUserProfile(_ profile: UserProfile) async throws
    func updateUserProfile(_ profile: UserProfile) async throws

    // Comments
    func fetchComments(episodeId: String, sortMode: CommentSortMode, limit: Int, after: DocumentSnapshot?) async throws -> ([Comment], DocumentSnapshot?)
    func createComment(_ comment: Comment) async throws
    func updateComment(_ comment: Comment) async throws
    func deleteComment(id: String) async throws

    // Votes
    func createVote(_ vote: Vote) async throws
    func deleteVote(id: String) async throws
    func fetchUserVote(commentId: String, userId: String) async throws -> Vote?

    // Watchlist
    func fetchWatchlistEntries(userId: String) async throws -> [WatchlistEntry]
    func createWatchlistEntry(_ entry: WatchlistEntry) async throws
    func updateWatchlistEntry(_ entry: WatchlistEntry) async throws
    func deleteWatchlistEntry(id: String) async throws

    // Listeners
    func addCommentsListener(episodeId: String, onChange: @Sendable @escaping ([Comment]) -> Void) -> any Sendable
    func removeListener(_ listener: any Sendable)
}
```

**File:** `Sequel/Core/Services/FirestoreService.swift`

Initial implementation with Firebase Firestore. Uses `Firestore.firestore()` to get the database reference. Each method maps to Firestore collection operations. Pagination uses `DocumentSnapshot` as cursor.

For the foundation sprint, implement the basic CRUD. Snapshot listeners are set up with proper detach patterns. Return types use our model structs directly since they're `Codable`.

```swift
actor FirestoreService: FirestoreServiceProtocol {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    func fetchComments(episodeId: String, sortMode: CommentSortMode, limit: Int, after: DocumentSnapshot?) async throws -> ([Comment], DocumentSnapshot?) {
        var query = db.collection("comments")
            .whereField("episodeId", isEqualTo: episodeId)
            // Sort based on sortMode
            .limit(to: limit)
        if let cursor = after {
            query = query.start(afterDocument: cursor)
        }
        let snapshot = try await query.getDocuments()
        let comments = try snapshot.documents.map { try $0.data(as: Comment.self) }
        return (comments, snapshot.documents.last)
    }

    // ... other methods
}
```

#### Step 6.3: Firestore Security Rules

**File:** `firestore.rules` (project root)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;

      match /watchlist/{entryId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // Comments: anyone can read, auth users can create, only author can edit/delete
    match /comments/{commentId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.authorId;
    }

    // Votes: 1 per user per comment, ID format enforced
    match /votes/{voteId} {
      allow read: if true;
      allow create: if request.auth != null
                    && voteId == resource.data.commentId + '_' + request.auth.uid;
      allow delete: if request.auth.uid == resource.data.userId;
    }

    // Notifications: user can only read/update their own
    match /notifications/{notifId} {
      allow read, update: if request.auth.uid == resource.data.userId;
    }
  }
}
```

---

### Phase 7: Navigation (4 files)

#### Step 7.1: Route Enum

**File:** `Sequel/Navigation/Route.swift`

```swift
enum Route: Hashable {
    case showDetail(tmdbId: Int)
    case episodeThread(showId: Int, season: Int, episode: Int)
    case search
    case settings
    case commentHistory
    case notifications
}

enum Sheet: Identifiable {
    case compose(episodeId: String, parentCommentId: String?)
    case addToWatchlist(tmdbId: Int)
    case changeStatus(entryId: String)
    case auth

    var id: String { ... }
}
```

#### Step 7.2: Router

**File:** `Sequel/Navigation/Router.swift`

```swift
@Observable
final class Router {
    var homePath = NavigationPath()
    var myShowsPath = NavigationPath()
    var profilePath = NavigationPath()
    var presentedSheet: Sheet?
    var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home, myShows, profile
    }

    func navigate(to route: Route) {
        switch selectedTab {
        case .home: homePath.append(route)
        case .myShows: myShowsPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    func pop() {
        switch selectedTab {
        case .home: if !homePath.isEmpty { homePath.removeLast() }
        case .myShows: if !myShowsPath.isEmpty { myShowsPath.removeLast() }
        case .profile: if !profilePath.isEmpty { profilePath.removeLast() }
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .home: homePath = NavigationPath()
        case .myShows: myShowsPath = NavigationPath()
        case .profile: profilePath = NavigationPath()
        }
    }

    func present(_ sheet: Sheet) {
        presentedSheet = sheet
    }
}
```

Note: Each tab has its own `NavigationPath` so navigation state is preserved when switching tabs.

#### Step 7.3: DeepLinkHandler Skeleton

**File:** `Sequel/Navigation/DeepLinkHandler.swift`

```swift
struct DeepLinkHandler {
    static func handle(url: URL, router: Router) {
        // showthread://show/{tmdbId}/season/{n}/episode/{n}
        guard url.scheme == "showthread",
              let host = url.host else { return }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "show":
            guard let tmdbIdStr = pathComponents.first,
                  let tmdbId = Int(tmdbIdStr) else { return }

            if pathComponents.count >= 4,
               pathComponents[1] == "season",
               let season = Int(pathComponents[2]),
               pathComponents[3].hasPrefix("episode"),
               // handle "episode" as path component followed by number
               pathComponents.count >= 5,
               let episode = Int(pathComponents[4]) {
                router.navigate(to: .episodeThread(showId: tmdbId, season: season, episode: episode))
            } else {
                router.navigate(to: .showDetail(tmdbId: tmdbId))
            }
        default:
            break
        }
    }
}
```

---

### Phase 8: App Shell + Tab Views (6 files)

#### Step 8.1: Replace App Entry Point

**File:** `Sequel/App/ShowThreadApp.swift`

This REPLACES the existing `Sequel/SequelApp.swift` (delete SequelApp.swift, create this).

```swift
import SwiftUI
import SwiftData
import FirebaseCore

@main
struct ShowThreadApp: App {
    @State private var router = Router()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    DeepLinkHandler.handle(url: url, router: router)
                }
        }
        .modelContainer(for: [
            Show.self,
            Season.self,
            Episode.self,
            WatchlistEntry.self
        ])
    }
}
```

**IMPORTANT:** Delete `Sequel/SequelApp.swift` first, then create `Sequel/App/ShowThreadApp.swift`. Two `@main` types will cause a compile error.

#### Step 8.2: ContentView with TabView

**File:** `Sequel/ContentView.swift` (overwrite existing)

```swift
import SwiftUI

struct ContentView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack(path: $router.homePath) {
                    HomeView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }

            Tab("My Shows", systemImage: "rectangle.stack.fill", value: .myShows) {
                NavigationStack(path: $router.myShowsPath) {
                    MyShowsView()
                        .navigationDestination(for: Route.self) { route in
                            destinationView(for: route)
                        }
                }
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView()
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

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .showDetail(let tmdbId):
            Text("Show Detail: \(tmdbId)")  // Placeholder
        case .episodeThread(let showId, let season, let episode):
            Text("Thread: S\(season)E\(episode)")  // Placeholder
        case .search:
            Text("Search")
        case .settings:
            Text("Settings")
        case .commentHistory:
            Text("Comment History")
        case .notifications:
            Text("Notifications")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .compose:
            Text("Compose")
        case .addToWatchlist:
            Text("Add to Watchlist")
        case .changeStatus:
            Text("Change Status")
        case .auth:
            Text("Sign In")
        }
    }
}
```

#### Step 8.3: Placeholder Tab Views

**File:** `Sequel/Features/Home/HomeView.swift`

```swift
import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: GlassTokens.paddingVertical) {
                Text("Trending Now")
                    .font(AppTypography.sectionHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, GlassTokens.paddingHorizontal)

                Text("Home content coming soon")
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.top)
        }
        .navigationTitle("Home")
    }
}
```

**File:** `Sequel/Features/MyShows/MyShowsView.swift`

```swift
import SwiftUI

struct MyShowsView: View {
    var body: some View {
        VStack {
            Text("Your watchlist is empty")
                .font(AppTypography.commentBody)
                .foregroundStyle(AppColors.secondaryText)
        }
        .navigationTitle("My Shows")
    }
}
```

**File:** `Sequel/Features/Profile/ProfileView.swift`

```swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Sign in to access your profile")
                .font(AppTypography.commentBody)
                .foregroundStyle(AppColors.secondaryText)
        }
        .navigationTitle("Profile")
    }
}
```

---

### Phase 9: Firebase Configuration File (1 file)

#### Step 9.1: GoogleService-Info.plist Placeholder

The real `GoogleService-Info.plist` must be downloaded from the Firebase Console. For now, create a note/comment in `ShowThreadApp.swift` that the file is needed. Do NOT create a fake plist — Firebase will crash at runtime without a valid one.

Instead, wrap `FirebaseApp.configure()` in a check:

```swift
init() {
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
        FirebaseApp.configure()
    } else {
        print("⚠️ GoogleService-Info.plist not found. Firebase not configured.")
    }
}
```

This allows the app to compile and run without Firebase during development.

---

## File Creation Order (Dependency-Aware)

The agent should create files in this exact order to avoid compile errors at each step:

### Batch 1: Independent foundations (no cross-dependencies)
1. `Sequel/Core/DesignSystem/GlassTokens.swift`
2. `Sequel/Core/DesignSystem/AppColors.swift`
3. `Sequel/Core/DesignSystem/AppTypography.swift`
4. `Sequel/Assets.xcassets/AccentColor.colorset/Contents.json` (overwrite)
5. `Sequel/Core/Models/Enums/ShowEnums.swift`
6. `Sequel/Core/Models/Enums/SortEnums.swift`
7. `Sequel/Core/Models/Enums/NotificationEnums.swift`
8. `Sequel/Utilities/Helpers/AppError.swift`
9. `Sequel/Utilities/Helpers/LoadingState.swift`
10. `Sequel/Utilities/Extensions/Date+Extensions.swift`

### Batch 2: Models (depend on Enums)
11. `Sequel/Core/Models/Show.swift`
12. `Sequel/Core/Models/Season.swift`
13. `Sequel/Core/Models/Episode.swift`
14. `Sequel/Core/Models/WatchlistEntry.swift`
15. `Sequel/Core/Models/Comment.swift`
16. `Sequel/Core/Models/Vote.swift`
17. `Sequel/Core/Models/UserProfile.swift`
18. `Sequel/Core/Models/AppNotification.swift`
19. `Sequel/Core/Models/StreamingLink.swift`

### Batch 3: Networking (depends on Models)
20. `Sequel/Core/Networking/APIConfig.swift`
21. `Sequel/Core/Networking/DTOs/TMDBDTOs.swift`
22. `Sequel/Utilities/Extensions/URL+TMDB.swift`
23. `Sequel/Core/Services/TMDBServiceProtocol.swift`
24. `Sequel/Core/Services/TMDBService.swift`
25. `Sequel/Core/Networking/DTOs/DTOMappers.swift`

### Batch 4: Firebase Services (depends on Models)
26. `Sequel/Core/Services/AuthServiceProtocol.swift`
27. `Sequel/Core/Services/AuthService.swift`
28. `Sequel/Core/Services/FirestoreServiceProtocol.swift`
29. `Sequel/Core/Services/FirestoreService.swift`
30. `firestore.rules`

### Batch 5: Navigation (depends on nothing but is used by Views)
31. `Sequel/Navigation/Route.swift`
32. `Sequel/Navigation/Router.swift`
33. `Sequel/Navigation/DeepLinkHandler.swift`

### Batch 6: Views (depends on everything above)
34. `Sequel/Features/Home/HomeView.swift`
35. `Sequel/Features/MyShows/MyShowsView.swift`
36. `Sequel/Features/Profile/ProfileView.swift`
37. `Sequel/ContentView.swift` (overwrite)
38. DELETE `Sequel/SequelApp.swift`
39. `Sequel/App/ShowThreadApp.swift`

### Batch 7: Project configuration
40. `Sequel/Info.plist`
41. `Sequel.xcodeproj/project.pbxproj` (edit for SPM deps + Info.plist + strict concurrency)

**IMPORTANT NOTE ON BATCH 7:** The pbxproj modification for SPM dependencies is the riskiest step. If the agent cannot reliably edit pbxproj, an alternative is to provide a `Package.swift` at the project root and convert to an SPM-based project. However, since we have an existing .xcodeproj with FileSystemSynchronizedRootGroup, the recommendation is:

1. First, get all Swift files compiling WITHOUT Firebase imports (comment them out in services)
2. Then add SPM dependencies to pbxproj
3. Then uncomment Firebase imports

This lets us validate the code structure before introducing the SPM complexity.

---

## Key Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| pbxproj SPM edits break project | Cannot build | Write SPM entries carefully; validate with `xcodebuild -list` after edit |
| SwiftData @Model + Codable conflicts | Compile errors | Use actor-isolated Codable conformance; test one model first |
| Swift 6.2 MainActor default + actor services | Isolation mismatches | Use `nonisolated protocol` for service protocols |
| Two @main structs during migration | Compile error | Delete SequelApp.swift BEFORE creating ShowThreadApp.swift |
| Missing GoogleService-Info.plist | Runtime crash | Guard FirebaseApp.configure() with file existence check |
| Firestore DocumentSnapshot in protocol | Type leaks Firebase into protocol | Use opaque cursor type or String-based pagination |

---

## Post-Sprint Verification

After all files are created, the app should:
1. Build without errors (with SPM deps resolved)
2. Launch to a 3-tab interface (Home, My Shows, Profile)
3. Tab switching works with navigation state preserved
4. No actual data loading (TMDB key not yet configured)
5. No auth flows (stubs only)
6. All models compile with correct Codable/Sendable conformance
7. `xcodebuild build` succeeds with strict concurrency checking
