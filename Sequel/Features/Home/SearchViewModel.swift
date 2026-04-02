import Foundation

@Observable
final class SearchViewModel {
    private(set) var results: [SearchResult] = []
    private(set) var isSearching = false
    private(set) var error: AppError?
    private(set) var recentSearches: [String] = []
    private(set) var trendingSearches: [String] = []
    var query = ""

    private let tmdbService: TMDBServiceProtocol
    private let debouncer = Debouncer()

    private static let recentSearchesKey = "ShowThread_RecentSearches"
    private static let recentSearchesDateKey = "ShowThread_RecentSearchesDates"
    private static let maxRecentSearches = 50
    private static let recentSearchTTL: TimeInterval = 30 * 24 * 60 * 60  // 30 days

    init(tmdbService: TMDBServiceProtocol = TMDBService.shared) {
        self.tmdbService = tmdbService
        loadRecentSearches()
    }

    // MARK: - Query Changed

    func onQueryChanged() {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
            error = nil
            return
        }
        Task {
            await debouncer.debounce(delay: .milliseconds(300)) { [weak self] in
                await self?.performSearch()
            }
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await tmdbService.searchMulti(query: trimmed)
            error = nil
        } catch {
            self.error = .from(error)
            results = []
        }
    }

    // MARK: - Recent Searches

    func addRecentSearch(_ searchTerm: String) {
        let trimmed = searchTerm.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Remove duplicates
        recentSearches.removeAll { $0 == trimmed }
        // Insert at beginning
        recentSearches.insert(trimmed, at: 0)
        // Limit to max
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }
        saveRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: Self.recentSearchesKey)
        UserDefaults.standard.removeObject(forKey: Self.recentSearchesDateKey)
    }

    func removeRecentSearch(_ term: String) {
        recentSearches.removeAll { $0 == term }
        saveRecentSearches()
    }

    private func loadRecentSearches() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []
        let savedDate = UserDefaults.standard.object(forKey: Self.recentSearchesDateKey) as? Date ?? .distantPast

        // Check 30-day TTL
        if Date.now.timeIntervalSince(savedDate) < Self.recentSearchTTL {
            recentSearches = saved
        } else {
            recentSearches = []
            UserDefaults.standard.removeObject(forKey: Self.recentSearchesKey)
        }
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: Self.recentSearchesKey)
        UserDefaults.standard.set(Date.now, forKey: Self.recentSearchesDateKey)
    }

    // MARK: - Trending Searches

    func loadTrendingSearches() async {
        do {
            let trending = try await tmdbService.fetchTrending()
            trendingSearches = trending.prefix(10).map(\.name)
        } catch {
            trendingSearches = []
        }
    }
}
