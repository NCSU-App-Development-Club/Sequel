import Foundation

@MainActor
final class TMDBService: TMDBServiceProtocol {
    static let shared = TMDBService()

    private let client = APIClient.shared
    private let base = APIConfig.tmdbBaseURL
    private let apiKey = APIConfig.tmdbAPIKey

    // 24h config cache
    private var cachedConfiguration: TMDBConfiguration?
    private var configurationFetchedAt: Date?
    private let configCacheDuration: TimeInterval = 24 * 60 * 60

    private init() {}

    // MARK: - Search

    func searchMulti(query: String) async throws -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        var components = URLComponents(string: "\(base)/search/multi")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        guard let url = components.url else { throw AppError.networkError("Invalid search URL") }
        let response: TMDBSearchResponse = try await client.request(url: url)
        return response.results.map { SearchResult(from: $0) }
    }

    // MARK: - Show Detail (with append_to_response batching)

    func fetchShow(id: Int) async throws -> TMDBShowDTO {
        var components = URLComponents(string: "\(base)/tv/\(id)")!
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else { throw AppError.networkError("Invalid show URL") }
        let show: TMDBShowDTO = try await client.request(url: url)

        let seasonCount = min(show.numberOfSeasons ?? 0, 20)
        if seasonCount > 0 {
            let seasonParams = (1...seasonCount).map { "season/\($0)" }.joined(separator: ",")
            var batchComponents = URLComponents(string: "\(base)/tv/\(id)")!
            batchComponents.queryItems = [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "append_to_response", value: "\(seasonParams),watch/providers")
            ]
            if let batchURL = batchComponents.url {
                return try await client.request(url: batchURL)
            }
        }
        return show
    }

    func fetchSeason(showId: Int, seasonNumber: Int) async throws -> TMDBSeasonDTO {
        var components = URLComponents(string: "\(base)/tv/\(showId)/season/\(seasonNumber)")!
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else { throw AppError.networkError("Invalid season URL") }
        return try await client.request(url: url)
    }

    func fetchMovie(id: Int) async throws -> TMDBMovieDTO {
        var components = URLComponents(string: "\(base)/movie/\(id)")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "append_to_response", value: "watch/providers")
        ]
        guard let url = components.url else { throw AppError.networkError("Invalid movie URL") }
        return try await client.request(url: url)
    }

    func fetchWatchProviders(showId: Int) async throws -> TMDBWatchProvidersResponse {
        var components = URLComponents(string: "\(base)/tv/\(showId)/watch/providers")!
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else { throw AppError.networkError("Invalid providers URL") }
        return try await client.request(url: url)
    }

    func fetchTrending() async throws -> [TMDBShowDTO] {
        var components = URLComponents(string: "\(base)/trending/tv/day")!
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else { throw AppError.networkError("Invalid trending URL") }
        let response: TMDBTrendingResponse = try await client.request(url: url)
        return response.results
    }

    // MARK: - Configuration (24h cache)

    func fetchConfiguration() async throws -> TMDBConfiguration {
        if let cached = cachedConfiguration,
           let fetchedAt = configurationFetchedAt,
           Date.now.timeIntervalSince(fetchedAt) < configCacheDuration {
            return cached
        }
        var components = URLComponents(string: "\(base)/configuration")!
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else { throw AppError.networkError("Invalid config URL") }
        let config: TMDBConfiguration = try await client.request(url: url)
        cachedConfiguration = config
        configurationFetchedAt = .now
        return config
    }
}
