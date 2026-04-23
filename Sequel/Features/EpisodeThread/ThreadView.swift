import SwiftUI
import SwiftData
import Kingfisher

struct ThreadView: View {
    let showId: Int
    let season: Int
    let episode: Int

    @State private var viewModel = EpisodeThreadViewModel()
    @Environment(\.modelContext) private var modelContext
    @Namespace private var sortNamespace
    @FocusState private var isComposeFieldFocused: Bool

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.episode == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let episodeData = viewModel.episode {
                threadContent(episodeData)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("S\(season)E\(episode)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadEpisode(
                showId: showId,
                season: season,
                episodeNumber: episode,
                context: modelContext
            )
        }
    }

    // MARK: - Content

    private func threadContent(_ episodeData: Episode) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Still image header
                    episodeHeader(episodeData)

                    VStack(alignment: .leading, spacing: 16) {
                        // Episode info
                        episodeInfo(episodeData)

                        // Overview
                        if let overview = episodeData.overview, !overview.isEmpty {
                            overviewSection(overview)
                        }

                        // Streaming links
                        if !viewModel.streamingLinks.isEmpty {
                            streamingSection
                        }

                        Divider()

                        // Sort control — tappable pills that switch the ViewModel's sort mode
                        sortControl

                        Divider()

                        // Comment thread — one CommentRow per comment
                        commentsSection

                        // Comment count footer
                        if !viewModel.sortedComments.isEmpty {
                            Text("\(viewModel.sortedComments.count) comments")
                                .font(.caption2)
                                .foregroundStyle(AppColors.tertiaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, GlassTokens.Padding.horizontal)
                }
                .padding(.bottom, 80)  // Space for compose bar
            }

            // Compose bar — real text field
            composeBar
        }
    }

    // MARK: - Header Image

    private func episodeHeader(_ episodeData: Episode) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let stillPath = episodeData.stillPath,
                   let url = APIConfig.stillHeaderURL(stillPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(16/9, contentMode: .fill)
                } else if let backdropPath = viewModel.show?.backdropPath,
                          let url = APIConfig.backdropHeroURL(backdropPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(16/9, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            // Gradient
            LinearGradient(
                colors: [.clear, Color(.systemBackground)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 80)
            .offset(y: 40)
        }
    }

    // MARK: - Episode Info

    private func episodeInfo(_ episodeData: Episode) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let showTitle = viewModel.show?.title {
                Text(showTitle)
                    .font(.metadata)
                    .foregroundStyle(.secondary)
            }

            Text(episodeData.name)
                .font(.showTitle)

            HStack(spacing: 12) {
                Label("S\(episodeData.seasonNumber)E\(episodeData.episodeNumber)", systemImage: "tv")
                    .font(.metadata)
                    .foregroundStyle(.secondary)

                if let airDate = episodeData.airDate {
                    Label(airDate.relativeString, systemImage: "calendar")
                        .font(.metadata)
                        .foregroundStyle(.secondary)
                }

                if let runtime = episodeData.runtime {
                    Label("\(runtime) min", systemImage: "clock")
                        .font(.metadata)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Overview

    private func overviewSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(viewModel.isOverviewExpanded ? nil : 3)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.isOverviewExpanded.toggle()
                }
            } label: {
                Text(viewModel.isOverviewExpanded ? "Show less" : "Read more")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.accent)
            }
        }
    }

    // MARK: - Streaming

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.isStreamingExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Where to Watch")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: viewModel.isStreamingExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if viewModel.isStreamingExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.streamingLinks) { link in
                            streamingPill(link)
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))

                Text("Streaming data provided by JustWatch via TMDB")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }

    private func streamingPill(_ link: StreamingLink) -> some View {
        Button {
            if let urlString = link.universalLinkURL, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: link.webURL) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                if let url = APIConfig.posterListURL(link.logoPath) {
                    KFImage(url)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text(link.providerName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sort Control

    /// Interactive sort pills — tapping one changes the sort mode on the ViewModel,
    /// which re-sorts `sortedComments` and SwiftUI automatically re-renders the list.
    private var sortControl: some View {
        HStack(spacing: 0) {
            ForEach(CommentSortMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedSortMode = mode
                    }
                } label: {
                    Text(mode.rawValue.capitalized)
                        .font(.caption.weight(viewModel.selectedSortMode == mode ? .bold : .regular))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if viewModel.selectedSortMode == mode {
                                Capsule()
                                    .fill(AppColors.accent.opacity(0.15))
                                    .matchedGeometryEffect(id: "sortPill", in: sortNamespace)
                            }
                        }
                        .foregroundStyle(viewModel.selectedSortMode == mode ? AppColors.accent : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Comments Section

    /// Renders one `CommentRow` per comment. `ForEach` is the "stamping" mechanism —
    /// it takes the `sortedComments` array and creates one view per element.
    /// When the sort mode changes, `sortedComments` returns a different order,
    /// and SwiftUI animates the rows into their new positions.
    private var commentsSection: some View {
        Group {
            if viewModel.sortedComments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No comments yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Be the first to start the discussion.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.sortedComments) { comment in
                        CommentRow(
                            comment: comment,
                            currentVote: viewModel.userVotes[comment.id],
                            onUpvote: { viewModel.toggleVote(commentId: comment.id, direction: .up) },
                            onDownvote: { viewModel.toggleVote(commentId: comment.id, direction: .down) },
                            onReply: {
                                viewModel.startReply(to: comment)
                                isComposeFieldFocused = true
                            }
                        )
                        Divider()
                            .padding(.leading, CGFloat(comment.depth) * GlassTokens.CommentIndent.perLevel)
                    }
                }
            }
        }
    }

    // MARK: - Compose Bar

    /// A real text field + send button pinned to the bottom of the screen.
    /// Typing and tapping send calls `viewModel.sendComment()`, which appends
    /// the new comment to the local array and clears the text field.
    private var composeBar: some View {
        VStack(spacing: 0) {
            // Reply context banner — shows who you're replying to
            if let replyTarget = viewModel.replyingTo {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColors.accent)
                    Text("Replying to @\(replyTarget.authorDisplayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.cancelReply()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, GlassTokens.Padding.horizontal)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Text field + send button
            HStack(spacing: 10) {
                TextField(
                    viewModel.replyingTo != nil ? "Write a reply..." : "Join the discussion...",
                    text: $viewModel.composeText
                )
                .font(.subheadline)
                .focused($isComposeFieldFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .submitLabel(.send)
                .onSubmit {
                    viewModel.sendComment()
                }

                Button {
                    viewModel.sendComment()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.composeText.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? .secondary
                                         : AppColors.accent)
                }
                .disabled(viewModel.composeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, GlassTokens.Padding.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}
