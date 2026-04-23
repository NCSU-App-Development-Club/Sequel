import SwiftUI

struct NotificationsView: View {
    private let notifications = MockProfileNotification.items

    var body: some View {
        List(notifications) { notification in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.showTitle)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(notification.createdAt.relativeString)
                        .font(.caption2)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MockProfileNotification: Identifiable {
    let id: String
    let showTitle: String
    let message: String
    let createdAt: Date

    static let items = [
        MockProfileNotification(
            id: "n1",
            showTitle: "Severance",
            message: "3 new replies in the finale thread.",
            createdAt: .now.addingTimeInterval(-1_200)
        ),
        MockProfileNotification(
            id: "n2",
            showTitle: "The Boys",
            message: "A new episode thread is available.",
            createdAt: .now.addingTimeInterval(-9_000)
        ),
        MockProfileNotification(
            id: "n3",
            showTitle: "The Good Place",
            message: "Your comment passed 50 upvotes.",
            createdAt: .now.addingTimeInterval(-26_000)
        )
    ]
}
