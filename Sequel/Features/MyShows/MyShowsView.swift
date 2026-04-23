import SwiftUI
import SwiftData
import Kingfisher

struct MyShowsView: View {
    @State private var viewModel = MyShowsViewModel()
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Namespace private var segmentNamespace

    @Query private var watchlistEntries: [WatchlistEntry]
    @Query private var shows: [Show]
    @Query private var episodes: [Episode]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                VStack(alignment: .leading, spacing: 20) {
                    statusSegments
                    summaryRow

                    if displayRows.isEmpty {
                        emptyState
                    }
                }
                .listRowInsets(EdgeInsets(top: 26, leading: 28, bottom: displayRows.isEmpty ? 110 : 4, trailing: 28))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if !displayRows.isEmpty {
                    ForEach(displayRows) { row in
                        showRow(row)
                            .listRowInsets(EdgeInsets(top: 0, leading: 28, bottom: 18, trailing: 28))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    remove(row, haptic: true)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }

                    Color.clear
                        .frame(height: 90)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("My Shows")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openSearch()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add show")
            }
        }
    }

    // MARK: - Derived State

    private var localEntries: [WatchlistEntry] {
        watchlistEntries.filter { $0.userId == "local_user" }
    }

    private var displayRows: [MyShowRowModel] {
        viewModel.rows(entries: watchlistEntries, shows: shows, episodes: episodes)
    }

    // MARK: - Layout

    private var statusSegments: some View {
        HStack(spacing: 4) {
            ForEach(WatchStatus.allCases, id: \.self) { status in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        viewModel.selectedStatus = status
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: status.myShowsIcon)
                            .font(.system(size: 12, weight: .semibold))

                        Text(status.myShowsLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.66)
                            .allowsTightening(true)
                    }
                    .foregroundStyle(status == viewModel.selectedStatus ? .white : .white.opacity(0.58))
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .padding(.horizontal, 4)
                    .background {
                        if status == viewModel.selectedStatus {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.white.opacity(0.16))
                                .matchedGeometryEffect(id: "selectedWatchStatus", in: segmentNamespace)
                                .watchlistGlass()
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(status == viewModel.selectedStatus ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .watchlistGlass()
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            Text(viewModel.countLabel(for: displayRows))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.42))

            Spacer()

            sortMenu
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(ShowListSortMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.sortMode = mode
                    }
                } label: {
                    Label(
                        mode.displayName,
                        systemImage: mode == viewModel.sortMode ? "checkmark.circle.fill" : "circle"
                    )
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .semibold))

                Text(viewModel.sortMode.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(.ultraThinMaterial, in: Capsule())
            .watchlistGlass()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sort shows")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(0.58))

            Text(viewModel.emptyStateTitle(totalSavedShows: localEntries.count))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(viewModel.emptyStateMessage(totalSavedShows: localEntries.count))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)

            Button {
                openSearch()
            } label: {
                Text("Browse Shows")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(AppColors.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .padding(.horizontal, 24)
        .background(Color(hex: "111111"), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func showRow(_ row: MyShowRowModel) -> some View {
        Button {
            openShow(row)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                posterView(for: row)

                VStack(alignment: .leading, spacing: 7) {
                    Text(row.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(row.metadataLine)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.46))
                        .lineLimit(1)

                    if !row.genres.isEmpty {
                        genreRow(row.genres)
                    }

                    if let nextEpisodeText = row.nextEpisodeText {
                        Label(nextEpisodeText, systemImage: "calendar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.accent)
                            .lineLimit(1)
                    }

                    if let progressText = row.progressText {
                        Text(progressText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.16))
                    .padding(.top, 36)
            }
            .padding(12)
            .background(Color(hex: "101010"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(WatchStatus.allCases, id: \.self) { status in
                Button {
                    updateStatus(status, for: row)
                } label: {
                    Label(
                        status.displayName,
                        systemImage: status == row.status ? "checkmark.circle.fill" : "circle"
                    )
                }
            }

            Divider()

            Button {
                toggleNotifications(for: row)
            } label: {
                Label(
                    row.notificationsEnabled ? "Mute Notifications" : "Turn Notifications On",
                    systemImage: row.notificationsEnabled ? "bell.slash" : "bell"
                )
            }

            Button(role: .destructive) {
                remove(row, haptic: true)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .accessibilityAction(named: "Remove") {
            remove(row, haptic: true)
        }
    }

    private func genreRow(_ genres: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(genres, id: \.self) { genre in
                Text(genre)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
        }
    }

    private func posterView(for row: MyShowRowModel) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let posterPath = row.posterPath,
                   let url = APIConfig.posterListURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                } else if let backdropPath = row.backdropPath,
                          let url = APIConfig.backdropCardURL(backdropPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "161616"))
                        .overlay(
                            Image(systemName: "film.fill")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.45))
                        )
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if row.unreadBadgeCount > 0 {
                Text("\(row.unreadBadgeCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(AppColors.accent, in: Circle())
                    .offset(x: 9, y: -9)
            }
        }
    }

    // MARK: - Actions

    private func openSearch() {
        router.navigate(to: .search, tab: .watchlist)
    }

    private func openShow(_ row: MyShowRowModel) {
        if let entry = watchlistEntries.first(where: { $0.id == row.id }) {
            entry.lastVisited = .now
            try? modelContext.save()
        }

        router.navigate(
            to: .showDetail(tmdbId: row.tmdbId, mediaType: row.mediaType),
            tab: .watchlist
        )
    }

    private func updateStatus(_ status: WatchStatus, for row: MyShowRowModel) {
        guard let entry = watchlistEntries.first(where: { $0.id == row.id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
            entry.status = status
            try? modelContext.save()
        }
    }

    private func toggleNotifications(for row: MyShowRowModel) {
        guard let entry = watchlistEntries.first(where: { $0.id == row.id }) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            entry.notificationsEnabled.toggle()
            try? modelContext.save()
        }
    }

    private func remove(_ row: MyShowRowModel, haptic: Bool = false) {
        guard let entry = watchlistEntries.first(where: { $0.id == row.id }) else { return }

        if haptic {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}

private extension View {
    @ViewBuilder
    func watchlistGlass() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}
