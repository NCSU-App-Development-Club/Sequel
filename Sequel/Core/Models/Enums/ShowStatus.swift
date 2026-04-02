import Foundation

enum ShowStatus: String, Codable, Sendable, CaseIterable {
    case airing
    case ended
    case upcoming
    case cancelled
}
