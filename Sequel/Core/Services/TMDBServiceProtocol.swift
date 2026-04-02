import Foundation

// @MainActor: in Swift 6.2 with MainActor default isolation, Codable conformances
// on DTO structs are @MainActor. Marking the protocol @MainActor lets the service
// call decoder.decode() without actor-boundary issues. URLSession I/O still
// suspends and runs on OS threads — the main thread is never blocked.
@MainActor
protocol TMDBServiceProtocol: AnyObject {
    func searchMulti(query: String) async throws -> [SearchResult]
    func fetchShow(id: Int) async throws -> TMDBShowDTO
    func fetchSeason(showId: Int, seasonNumber: Int) async throws -> TMDBSeasonDTO
    func fetchMovie(id: Int) async throws -> TMDBMovieDTO
    func fetchWatchProviders(showId: Int) async throws -> TMDBWatchProvidersResponse
    func fetchTrending() async throws -> [TMDBShowDTO]
    func fetchConfiguration() async throws -> TMDBConfiguration
}
