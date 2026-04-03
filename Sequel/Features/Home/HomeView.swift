import SwiftUI
import SwiftData
import Kingfisher

struct HomeView: View {
    @State private var homeViewModel = HomeViewModel()
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .top) {
            // Main scrollable content
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

            // Floating top bar: "Home" + profile avatar
            topBar
        }
        .navigationBarHidden(true)
        .refreshable {
            await homeViewModel.refresh(context: modelContext)
        }
        .task {
            await homeViewModel.loadFeed(context: modelContext)
        }
    }

    // MARK: - Top Bar (floating over hero)

    private var topBar: some View {
        HStack {
            Text("Home")
                .font(.title.bold())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

            Spacer()

            // Profile avatar button
            Button {
                router.navigate(to: .settings)
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Loading

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero shimmer
                ShimmerView()
                    .frame(height: 520)

                VStack(spacing: 24) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 12) {
                            ShimmerView()
                                .frame(width: 160, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(.horizontal, 16)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        ShimmerView()
                                            .frame(width: 180, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.top, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Feed

    private func feedView(_ feed: HomeFeed) -> some View {
        ScrollView {
            LazyVStack(spacing: 28) {
                // Hero banner
                if !feed.trending.isEmpty {
                    HeroBannerView(
                        shows: Array(feed.trending.prefix(5)),
                        onTap: { show in navigateToShow(show) },
                        onBookmark: { show in bookmark(show) },
                        isBookmarked: { id in homeViewModel.isBookmarked(tmdbId: id, context: modelContext) }
                    )
                }

                // From Your Watchlist
                WatchlistFeedSection(
                    episodes: feed.watchlistEpisodes,
                    onTapShow: { tmdbId, mediaType in
                        router.navigate(to: .showDetail(tmdbId: tmdbId, mediaType: mediaType))
                    }
                )

                // Recently Aired
                if !feed.recentlyAired.isEmpty {
                    RecentlyAiredSection(
                        shows: feed.recentlyAired,
                        onTap: { show in navigateToShow(show) }
                    )
                }

                // Discover
                if !feed.discover.isEmpty {
                    DiscoverSection(
                        shows: feed.discover,
                        onTap: { show in navigateToShow(show) },
                        onBookmark: { show in bookmark(show) },
                        isBookmarked: { id in homeViewModel.isBookmarked(tmdbId: id, context: modelContext) }
                    )
                }

                // Bottom spacing for tab bar
                Spacer(minLength: 60)
            }
        }
        .ignoresSafeArea(edges: .top)
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
