import SwiftUI
import Kingfisher

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Group {
                if viewModel.query.isEmpty {
                    suggestionsView
                } else if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.results.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $vm.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search shows and movies"
            )
            .onChange(of: viewModel.query) { _, _ in
                viewModel.onQueryChanged()
            }
            .task {
                await viewModel.loadTrendingSearches()
            }
        }
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        List {
            if !viewModel.recentSearches.isEmpty {
                Section {
                    ForEach(viewModel.recentSearches, id: \.self) { term in
                        Button {
                            viewModel.query = term
                            viewModel.onQueryChanged()
                        } label: {
                            Label(term, systemImage: "clock")
                                .foregroundStyle(.primary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removeRecentSearch(term)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent")
                        Spacer()
                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                    }
                }
            }

            if !viewModel.trendingSearches.isEmpty {
                Section("Trending") {
                    ForEach(viewModel.trendingSearches, id: \.self) { term in
                        Button {
                            viewModel.query = term
                            viewModel.onQueryChanged()
                        } label: {
                            Label(term, systemImage: "arrow.up.right")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Results

    private var resultsList: some View {
        List(viewModel.results) { result in
            resultRow(result)
                .onTapGesture {
                    viewModel.addRecentSearch(result.title)
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

    private func resultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
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
}
