import SwiftUI
import SwiftData
import Kingfisher

struct HomeView: View {
    @State private var homeViewModel = HomeViewModel()
    @State private var searchViewModel = SearchViewModel()
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var searchVM = searchViewModel

        Group {
            if searchViewModel.query.isEmpty {
                homeContent
            } else {
                searchResultsOverlay
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchVM.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search shows and movies"
        )
        .onChange(of: searchViewModel.query) { _, _ in
            searchViewModel.onQueryChanged()
        }
        .refreshable {
            await homeViewModel.refresh(context: modelContext)
        }
        .task {
            await homeViewModel.loadFeed(context: modelContext)
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        Group {
            switch homeViewModel.loadingState {
            case .idle, .loading:
                loadingView
            case .loaded(let feed):
                feedView(feed)
            case .error(let error):
                errorView(error)
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Shimmer trending
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in
                            ShimmerView()
                                .frame(width: 300, height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: GlassTokens.CornerRadius.showCard))
                        }
                    }
                    .padding(.horizontal, GlassTokens.Padding.horizontal)
                }
                .padding(.top, 8)

                // Shimmer rows
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ShimmerView()
                            .frame(width: 50, height: 75)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading, spacing: 8) {
                            ShimmerView()
                                .frame(height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            ShimmerView()
                                .frame(width: 150, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, GlassTokens.Padding.horizontal)
                }
            }
        }
    }

    // MARK: - Feed

    private func feedView(_ feed: HomeFeed) -> some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                // Section A: Trending
                if !feed.trending.isEmpty {
                    TrendingCarouselView(
                        shows: feed.trending,
                        onTap: { show in navigateToShow(show) },
                        onBookmark: { show in bookmark(show) },
                        isBookmarked: { id in homeViewModel.isBookmarked(tmdbId: id, context: modelContext) }
                    )
                }

                // Section B: Watchlist
                WatchlistFeedSection(
                    episodes: feed.watchlistEpisodes,
                    onTapShow: { tmdbId, mediaType in
                        router.navigate(to: .showDetail(tmdbId: tmdbId, mediaType: mediaType))
                    }
                )

                // Divider
                if !feed.recentlyAired.isEmpty {
                    Divider()
                        .padding(.horizontal, GlassTokens.Padding.horizontal)
                }

                // Section C: Recently Aired
                if !feed.recentlyAired.isEmpty {
                    RecentlyAiredSection(
                        shows: feed.recentlyAired,
                        onTap: { show in navigateToShow(show) }
                    )
                }

                // Divider
                if !feed.discover.isEmpty {
                    Divider()
                        .padding(.horizontal, GlassTokens.Padding.horizontal)
                }

                // Section D: Discover
                if !feed.discover.isEmpty {
                    DiscoverSection(
                        shows: feed.discover,
                        onTap: { show in navigateToShow(show) },
                        onBookmark: { show in bookmark(show) },
                        isBookmarked: { id in homeViewModel.isBookmarked(tmdbId: id, context: modelContext) }
                    )
                }

                // Bottom spacing
                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Error

    private func errorView(_ error: AppError) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                Task {
                    await homeViewModel.refresh(context: modelContext)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Search Results Overlay

    private var searchResultsOverlay: some View {
        Group {
            if searchViewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchViewModel.results.isEmpty && !searchViewModel.query.isEmpty {
                ContentUnavailableView.search(text: searchViewModel.query)
            } else {
                List(searchViewModel.results) { result in
                    searchResultRow(result)
                        .onTapGesture {
                            searchViewModel.addRecentSearch(result.title)
                            router.navigate(to: .showDetail(
                                tmdbId: result.id,
                                mediaType: result.mediaType
                            ))
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Search Result Row

    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            // Poster
            Group {
                if let posterPath = result.posterPath,
                   let url = APIConfig.posterListURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(width: 56, height: 84)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: GlassTokens.CornerRadius.showCard))
                } else {
                    RoundedRectangle(cornerRadius: GlassTokens.CornerRadius.showCard)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 56, height: 84)
                        .overlay(Image(systemName: "film").foregroundStyle(.secondary))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.episodeTitle)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let dateStr = result.firstAirDate, dateStr.count >= 4 {
                        Text(String(dateStr.prefix(4)))
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }

                    Text(result.mediaType == .movie ? "Movie" : "TV Show")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            result.mediaType == .movie
                                ? Color.blue.opacity(0.15)
                                : Color.purple.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(result.mediaType == .movie ? .blue : .purple)
                }

                if result.voteAverage > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", result.voteAverage))
                            .font(.metadata)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Helpers

    private func navigateToShow(_ show: ShowPreview) {
        router.navigate(to: .showDetail(tmdbId: show.id, mediaType: show.mediaType))
    }

    private func bookmark(_ show: ShowPreview) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        homeViewModel.toggleBookmark(showPreview: show, context: modelContext)
    }
}
