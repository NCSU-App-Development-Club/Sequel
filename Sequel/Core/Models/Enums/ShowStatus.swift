import Foundation

enum ShowStatus: String, Codable, Sendable, CaseIterable {
    case airing
    case ended
    case upcoming
    case cancelled

    var displayName: String {
        switch self {
        case .airing: "Airing"
        case .ended: "Ended"
        case .upcoming: "Upcoming"
        case .cancelled: "Cancelled"
        }
    }
}
