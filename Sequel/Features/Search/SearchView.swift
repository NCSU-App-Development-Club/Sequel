import SwiftUI
import Kingfisher

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(Router.self) private var router
    @Environment(\.dismissSearch) private var dismissSearch
    @State private var selectedFilter: SearchFilter = .topResults

    enum SearchFilter: String, CaseIterable {
        case topResults = "Top Results"
        case tvShows = "TV Shows"
        case movies = "Movies"
    }

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // Content
            Group {
                if viewModel.query.isEmpty {
                    trendingView
                } else if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredResults.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else {
                    resultsList
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $vm.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Shows, movies, and more"
        )
        .onChange(of: viewModel.query) { _, _ in
            viewModel.onQueryChanged()
        }
        .task {
            await viewModel.loadTrendingSearches()
        }
    }

    // MARK: - Filtered Results

    private var filteredResults: [SearchResult] {
        switch selectedFilter {
        case .topResults:
            return viewModel.results
        case .tvShows:
            return viewModel.results.filter { $0.mediaType == .tvShow }
        case .movies:
            return viewModel.results.filter { $0.mediaType == .movie }
        }
    }

    // MARK: - Trending (empty query state)

    private var trendingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent")
                                .font(.title3.bold())
                            Spacer()
                            Button("Clear") {
                                viewModel.clearRecentSearches()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)

                        ForEach(viewModel.recentSearches.prefix(5), id: \.self) { term in
                            Button {
                                viewModel.query = term
                                viewModel.onQueryChanged()
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text(term)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !viewModel.trendingSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trending")
                            .font(.title3.bold())
                            .padding(.horizontal, 16)

                        ForEach(viewModel.trendingSearches, id: \.self) { term in
                            Button {
                                viewModel.query = term
                                viewModel.onQueryChanged()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.right")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text(term)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        VStack(spacing: 0) {
            // Filter pills
            filterBar

            // Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredResults) { result in
                        Button {
                            openDetails(for: result)
                        } label: {
                            resultRow(result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(SearchFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline.weight(selectedFilter == filter ? .bold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedFilter == filter
                                ? Color.accentColor
                                : Color(.systemGray5),
                            in: Capsule()
                        )
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Result Row (Apple TV style)

    private func resultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            // Square poster thumbnail
            Group {
                if let posterPath = result.posterPath,
                   let url = APIConfig.posterListURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "film").foregroundStyle(.secondary))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 2) {
                    Text(result.mediaType == .movie ? "Movie" : "TV Show")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let dateStr = result.firstAirDate, dateStr.count >= 4 {
                        Text(" \u{00B7} \(String(dateStr.prefix(4)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            // Three-dot menu
            Button {
                // Context action placeholder
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func openDetails(for result: SearchResult) {
        viewModel.addRecentSearch(result.title)
        dismissSearch()

        let destinationTab: AppTab = router.selectedTab == .search ? .home : router.selectedTab
        router.selectedTab = destinationTab
        router.navigate(
            to: .showDetail(
                tmdbId: result.id,
                mediaType: result.mediaType
            ),
            tab: destinationTab
        )
    }
}
