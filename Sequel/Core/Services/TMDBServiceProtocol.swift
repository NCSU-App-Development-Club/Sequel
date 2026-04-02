import Foundation

protocol TMDBServiceProtocol: Sendable {
    func searchMulti(query: String) async throws -> [SearchResult]
    func fetchShow(id: Int) async throws -> TMDBShowDTO
    func fetchSeason(showId: Int, seasonNumber: Int) async throws -> TMDBSeasonDTO
    func fetchMovie(id: Int) async throws -> TMDBMovieDTO
    func fetchWatchProviders(showId: Int) async throws -> TMDBWatchProvidersResponse
    func fetchTrending() async throws -> [TMDBShowDTO]
    func fetchConfiguration() async throws -> TMDBConfiguration
}
