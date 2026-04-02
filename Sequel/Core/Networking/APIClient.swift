import Foundation

// @MainActor so synthesized Codable conformances (also @MainActor under Swift 6.2
// default isolation) can be used to decode. URLSession suspends for network I/O
// on OS threads, so the main thread is never blocked.
@MainActor
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let iso = ISO8601DateFormatter()
            if let date = iso.date(from: dateString) { return date }

            let tmdb = DateFormatter()
            tmdb.dateFormat = "yyyy-MM-dd"
            tmdb.locale = Locale(identifier: "en_US_POSIX")
            if let date = tmdb.date(from: dateString) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        self.decoder = decoder
    }

    func request<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AppError.decodingError(error.localizedDescription)
            }
        case 401: throw AppError.unauthorized
        case 404: throw AppError.notFound
        case 429: throw AppError.rateLimited
        default:  throw AppError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
}
