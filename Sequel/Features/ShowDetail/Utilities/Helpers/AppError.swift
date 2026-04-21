import Foundation

enum AppError: Error, Sendable, LocalizedError {
    case networkError(String)
    case decodingError(String)
    case authError(String)
    case firestoreError(String)
    case tmdbError(String)
    case notFound
    case unauthorized
    case rateLimited
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): msg
        case .decodingError(let msg): msg
        case .authError(let msg): msg
        case .firestoreError(let msg): msg
        case .tmdbError(let msg): msg
        case .notFound: "The requested resource was not found."
        case .unauthorized: "You must be signed in to do that."
        case .rateLimited: "Too many requests. Please try again shortly."
        case .unknown(let msg): msg
        }
    }

    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        if let urlError = error as? URLError {
            return .networkError(urlError.localizedDescription)
        }
        if error is DecodingError {
            return .decodingError(error.localizedDescription)
        }
        return .unknown(error.localizedDescription)
    }
}
