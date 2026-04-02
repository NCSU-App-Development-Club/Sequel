import Foundation

enum Route: Hashable {
    case showDetail(tmdbId: Int)
    case episodeThread(showId: Int, season: Int, episode: Int)
    case search
    case settings
    case notifications
    case commentHistory
}

enum Sheet: Identifiable {
    case statusPicker(tmdbId: Int)
    case compose(episodeId: String, parentCommentId: String?)
    case addShow

    var id: String {
        switch self {
        case .statusPicker(let id): "statusPicker_\(id)"
        case .compose(let id, _): "compose_\(id)"
        case .addShow: "addShow"
        }
    }
}
