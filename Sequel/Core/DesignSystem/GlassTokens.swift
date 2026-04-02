import SwiftUI

enum GlassTokens {
    enum CornerRadius {
        static let showCard: CGFloat = 12
        static let commentCard: CGFloat = 8
    }

    enum Padding {
        static let horizontal: CGFloat = 16
        static let vertical: CGFloat = 12
    }

    enum CommentIndent {
        static let perLevel: CGFloat = 16
        static let maxDepth: Int = 5
        static let maxIndent: CGFloat = 80
    }

    enum AvatarSize {
        static let profile: CGFloat = 80
        static let detail: CGFloat = 40
        static let inline: CGFloat = 24
    }

    enum Stroke {
        static let thin: CGFloat = 0.5
        static let regular: CGFloat = 1
    }

    static let touchTargetMin: CGFloat = 44
}
