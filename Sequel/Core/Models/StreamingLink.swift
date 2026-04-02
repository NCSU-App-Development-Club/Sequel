import Foundation

struct StreamingLink: Codable, Identifiable, Sendable, Hashable {
    var id: Int
    var providerName: String
    var logoPath: String
    var webURL: String
    var universalLinkURL: String?
    var type: StreamingType
}
