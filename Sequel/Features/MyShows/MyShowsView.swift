import SwiftUI
import SwiftData
import Kingfisher

struct MyShowsView: View {
    @State private var viewModel = MyShowsViewModel()
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query private var watchlistEntries: [WatchlistEntry]
    @Query private var shows: [Show]
    @Query private var episodes: [Episode]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    statusSegments
                    countRow

                    if displayRows.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 22) {
                            ForEach(displayRows) { row in
                                showRow(row)
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 26)
                .padding(.bottom, 110)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Derived State

    private var localEntries: [WatchlistEntry] {
        watchlistEntries.filter { $0.userId == "local_user" }
    }

    private var displayRows: [MyShowRowModel] {
        viewModel.rows(entries: watchlistEntries, shows: shows, episodes: episodes)
    }

    // MARK: - Layout

    private var header: some View {
        HStack(spacing: 12) {
            Text("My Shows")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                openSearch()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "1C1C1E"), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add show")
        }
        .padding(.bottom, 6)
    }

    private var statusSegments: some View {
        HStack(spacing: 6) {
            ForEach(WatchStatus.allCases, id: \.self) { status in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                        viewModel.selectedStatus = status
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: status.myShowsIcon)
                            .font(.system(size: 13, weight: .medium))
                        Text(status.myShowsLabel)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .allowsTightening(true)
                    }
                    .foregroundStyle(segmentForeground(for: status))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(segmentBackground(for: status), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color(hex: "111111"), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var countRow: some View {
        Text(viewModel.countLabel(for: displayRows))
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.white.opacity(0.34))
            .padding(.top, 4)
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
        .background(Color(hex: "111111"), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func showRow(_ row: MyShowRowModel) -> some View {
        Button {
            openShow(row)
        } label: {
            HStack(spacing: 14) {
                posterView(for: row)

                VStack(alignment: .leading, spacing: 6) {
                    Text(row.title)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(row.metadataLine)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.34))
                        .lineLimit(1)

                    if let nextEpisodeText = row.nextEpisodeText {
                        Text(nextEpisodeText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.accent)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.15))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(WatchStatus.allCases, id: \.self) { status in
                Button {
                    updateStatus(status, for: row)
                } label: {
                    Label(
                        status.displayName,
                        systemImage: status == viewModel.selectedStatus ? "checkmark.circle.fill" : "circle"
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
                remove(row)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func posterView(for row: MyShowRowModel) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let backdropPath = row.backdropPath,
                   let url = APIConfig.backdropCardURL(backdropPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                } else if let posterPath = row.posterPath,
                          let url = APIConfig.posterListURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "161616"))
                        .overlay(
                            Image(systemName: "film.fill")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.45))
                        )
                }
            }
            .frame(width: 102, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if row.unreadBadgeCount > 0 {
                Text("\(row.unreadBadgeCount)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(AppColors.accent, in: Circle())
                    .offset(x: 10, y: -10)
            }
        }
    }

    // MARK: - Helpers

    private func segmentForeground(for status: WatchStatus) -> Color {
        status == viewModel.selectedStatus ? .white : .white.opacity(0.5)
    }

    private func segmentBackground(for status: WatchStatus) -> Color {
        status == viewModel.selectedStatus ? .white.opacity(0.14) : .clear
    }

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

    private func remove(_ row: MyShowRowModel) {
        guard let entry = watchlistEntries.first(where: { $0.id == row.id }) else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}
