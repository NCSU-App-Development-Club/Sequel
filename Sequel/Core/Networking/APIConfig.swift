import Foundation

enum APIConfig {
    static let tmdbBaseURL = "https://api.themoviedb.org/3"

    static var tmdbAPIKey: String? {
        guard let key = Bundle.main.infoDictionary?["TMDB_API_KEY"] as? String,
              !key.isEmpty,
              !key.hasPrefix("$(") else {
            return nil
        }
        return key
    }

    enum ImageSize {
        static let posterList = "w342"
        static let posterDetail = "w500"
        static let backdropHero = "w780"
        static let backdropCard = "w300"
        static let stillList = "w300"
        static let stillHeader = "w780"
    }

    static let defaultImageBaseURL = "https://image.tmdb.org/t/p/"

    static func posterListURL(_ path: String) -> URL? {
        URL(string: "\(defaultImageBaseURL)\(ImageSize.posterList)\(path)")
    }

    static func posterDetailURL(_ path: String) -> URL? {
        URL(string: "\(defaultImageBaseURL)\(ImageSize.posterDetail)\(path)")
    }

    static func backdropHeroURL(_ path: String) -> URL? {
        URL(string: "\(defaultImageBaseURL)\(ImageSize.backdropHero)\(path)")
    }

    static func backdropCardURL(_ path: String) -> URL? {
        URL(string: "\(defaultImageBaseURL)\(ImageSize.backdropCard)\(path)")
    }

    static func stillListURL(_ path: String) -> URL? {
        URL(string: "\(defaultImageBaseURL)\(ImageSize.stillList)\(path)")
    }

    static func stillHeaderURL(_ path: String) -> URL? {
        URL(string: "\(defaultImageBaseURL)\(ImageSize.stillHeader)\(path)")
    }
}
