import SwiftUI
import SwiftData
import Kingfisher

struct ThreadView: View {
    let showId: Int
    let season: Int
    let episode: Int

    @State private var viewModel = EpisodeThreadViewModel()
    @Environment(\.modelContext) private var modelContext

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

                        // Sort control placeholder
                        sortControlPlaceholder

                        Divider()

                        // Comments placeholder
                        commentsPlaceholder
                    }
                    .padding(.horizontal, GlassTokens.Padding.horizontal)
                }
                .padding(.bottom, 80)  // Space for compose bar
            }

            // Compose bar placeholder
            composeBarPlaceholder
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

    // MARK: - Sort Control Placeholder

    private var sortControlPlaceholder: some View {
        HStack(spacing: 0) {
            ForEach(["Hot", "Top", "New", "Controversial"], id: \.self) { label in
                Text(label)
                    .font(.caption.weight(label == "Hot" ? .bold : .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        label == "Hot" ? AppColors.accent.opacity(0.15) : Color.clear,
                        in: Capsule()
                    )
                    .foregroundStyle(label == "Hot" ? AppColors.accent : .secondary)
            }
        }
    }

    // MARK: - Comments Placeholder

    private var commentsPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Comments coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("The discussion engine will be built in Sprint 3.")
                .font(.subheadline)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Compose Bar Placeholder

    private var composeBarPlaceholder: some View {
        HStack {
            Text("Join the discussion...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "paperplane.fill")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, GlassTokens.Padding.horizontal)
        .padding(.bottom, 8)
    }
}
