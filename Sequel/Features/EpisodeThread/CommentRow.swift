import SwiftUI

/// A reusable template for rendering a single comment in an episode thread.
///
/// **How this works (for Manish):**
/// - `CommentRow` is a generic "stamp" — it defines the *shape* of every comment.
/// - You pass in a `Comment` struct, and SwiftUI fills the template with that comment's data.
/// - In `ThreadView`, we loop `ForEach(comments) { comment in CommentRow(comment: comment) }`
///   which stamps out one of these for every comment in the list.
/// - The `depth` property on `Comment` controls indentation for nested replies.
struct CommentRow: View {
    let comment: Comment

    /// The user's current vote on this comment (nil = no vote).
    /// Passed in from the parent so CommentRow doesn't need to know about the ViewModel.
    let currentVote: VoteValue?

    /// Closures fired when the user taps vote/reply — the parent (ThreadView) wires these
    /// to the ViewModel's methods. This keeps CommentRow reusable and decoupled.
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onReply: () -> Void

    /// Whether the user has revealed a spoiler comment (local per-row state)
    @State private var isSpoilerRevealed = false

    /// Whether this comment contains spoiler text (simple heuristic for demo)
    private var isSpoiler: Bool {
        comment.body.lowercased().contains("[spoiler]")
    }

    /// The display body with the [spoiler] tag stripped out
    private var displayBody: String {
        comment.body.replacingOccurrences(of: "[spoiler]", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
    }

    // Deterministic avatar color based on the author's name
    private var avatarColor: Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal,
            .cyan, .blue, .indigo, .purple, .pink
        ]
        let hash = abs(comment.authorDisplayName.hashValue)
        return colors[hash % colors.count]
    }

    // Indentation for threaded replies — uses the design system's per-level indent
    private var indentation: CGFloat {
        let depth = min(comment.depth, GlassTokens.CommentIndent.maxDepth)
        return min(
            CGFloat(depth) * GlassTokens.CommentIndent.perLevel,
            GlassTokens.CommentIndent.maxIndent
        )
    }

    /// Color for the upvote arrow — orange when active, gray otherwise
    private var upvoteColor: Color {
        currentVote == .up ? .orange : .secondary
    }

    /// Color for the downvote arrow — blue when active, gray otherwise
    private var downvoteColor: Color {
        currentVote == .down ? Color(hex: "7193FF") : .secondary
    }

    /// Color for the score text — matches whichever vote direction is active
    private var scoreColor: Color {
        switch currentVote {
        case .up: return .orange
        case .down: return Color(hex: "7193FF")
        case nil: return .secondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Thread line for nested comments
            if comment.depth > 0 {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: GlassTokens.Stroke.thin)
                    .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Author row: avatar + name + timestamp
                authorRow

                // Comment body (with optional spoiler overlay)
                commentBody

                // Actions: vote buttons + reply
                actionBar
            }
        }
        .padding(.leading, indentation)
        .padding(.vertical, 4)
    }

    // MARK: - Author Row

    private var authorRow: some View {
        HStack(spacing: 8) {
            // Colored circle avatar with first letter of username
            Circle()
                .fill(avatarColor)
                .frame(width: GlassTokens.AvatarSize.inline, height: GlassTokens.AvatarSize.inline)
                .overlay(
                    Text(String(comment.authorDisplayName.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )

            Text(comment.authorDisplayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)

            Text(comment.createdAt.relativeString)
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)

            Spacer()
        }
    }

    // MARK: - Comment Body

    @ViewBuilder
    private var commentBody: some View {
        if isSpoiler && !isSpoilerRevealed {
            // Spoiler overlay — tapping reveals the text underneath
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSpoilerRevealed = true
                }
            } label: {
                Text("Tap to reveal spoiler")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: GlassTokens.CornerRadius.commentCard)
                            .fill(Color(.systemGray5))
                    )
            }
            .buttonStyle(.plain)
        } else {
            Text(isSpoiler ? displayBody : comment.body)
                .font(.commentBody)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Action Bar (Vote + Reply)

    private var actionBar: some View {
        HStack(spacing: 16) {
            // Vote controls: tappable up arrow, score, tappable down arrow
            HStack(spacing: 4) {
                // Upvote button — orange when active
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        onUpvote()
                    }
                } label: {
                    Image(systemName: currentVote == .up ? "arrow.up.circle.fill" : "arrow.up")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(upvoteColor)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)

                // Net score — color matches the active vote direction
                Text("\(comment.netScore)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(scoreColor)
                    .contentTransition(.numericText())

                // Downvote button — blue when active
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        onDownvote()
                    }
                } label: {
                    Image(systemName: currentVote == .down ? "arrow.down.circle.fill" : "arrow.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(downvoteColor)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
            }

            // Reply button
            Button {
                onReply()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .font(.caption2)
                    Text("Reply")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
