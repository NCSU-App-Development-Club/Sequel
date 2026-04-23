import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                profileHeader
                activitySummary
                profileActions
                recentComments
            }
            .padding(.horizontal, GlassTokens.Padding.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                avatar

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.profile.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.primaryText)

                    if let bio = viewModel.profile.bio {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                            .lineLimit(3)
                    }
                }
            }

            HStack(spacing: 8) {
                Label("\(viewModel.profile.karma) karma", systemImage: "arrow.up.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.accent)

                Text("Joined \(viewModel.profile.joinedAt.relativeString)")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()
            }

            Text("Tracking \(viewModel.trackedShowCount) shows")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(18)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var avatar: some View {
        Button {
            // Mock-only: real avatar selection belongs with auth/storage work.
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent, Color(hex: "00B8A9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: GlassTokens.AvatarSize.profile, height: GlassTokens.AvatarSize.profile)
                    .overlay(
                        Text(String(viewModel.profile.displayName.prefix(1)).uppercased())
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    )

                Image(systemName: "camera.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(AppColors.accent, in: Circle())
                    .overlay(Circle().stroke(AppColors.cardBackground, lineWidth: 2))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change avatar")
    }

    private var activitySummary: some View {
        HStack(spacing: 12) {
            metricCard(title: "Upvotes", value: "\(viewModel.upvoteKarma)", icon: "arrow.up")
            metricCard(title: "Downvotes", value: "\(viewModel.downvoteKarma)", icon: "arrow.down")
            metricCard(title: "Comments", value: "\(viewModel.commentHistory.count)", icon: "bubble.left.and.bubble.right")
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.accent)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppColors.primaryText)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var profileActions: some View {
        VStack(spacing: 0) {
            NavigationLink {
                CommentHistoryView(viewModel: viewModel)
            } label: {
                settingsRow(title: "Comment History", subtitle: "Recent posts and votes", icon: "text.bubble")
            }

            Divider().padding(.leading, 52)

            NavigationLink {
                SettingsView()
            } label: {
                settingsRow(title: "Settings", subtitle: "Appearance, spoilers, account", icon: "gearshape")
            }
        }
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func settingsRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.accent)
                .frame(width: 32, height: 32)
                .background(AppColors.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.tertiaryText)
        }
        .contentShape(Rectangle())
        .padding(14)
    }

    private var recentComments: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Comments")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                NavigationLink("View all") {
                    CommentHistoryView(viewModel: viewModel)
                }
                .font(.subheadline.weight(.semibold))
            }

            VStack(spacing: 0) {
                ForEach(viewModel.visibleComments.prefix(3)) { item in
                    CommentHistoryRow(item: item)
                    if item.id != viewModel.visibleComments.prefix(3).last?.id {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct CommentHistoryView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        List {
            ForEach(viewModel.visibleComments) { item in
                NavigationLink {
                    ThreadView(showId: item.showId, season: item.seasonNumber, episode: item.episodeNumber)
                } label: {
                    CommentHistoryRow(item: item)
                }
                .listRowSeparator(.hidden)
            }

            if viewModel.hasMoreComments {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.loadMoreComments()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Load more")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Comment History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CommentHistoryRow: View {
    let item: ProfileCommentHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.showTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Label("\(item.netVotes)", systemImage: "arrow.up.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(item.netVotes >= 0 ? AppColors.accent : AppColors.destructive)
            }

            Text(item.episodeLabel)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
                .lineLimit(1)

            Text(item.body)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(2)

            Text(item.createdAt.relativeString)
                .font(.caption2)
                .foregroundStyle(AppColors.tertiaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
