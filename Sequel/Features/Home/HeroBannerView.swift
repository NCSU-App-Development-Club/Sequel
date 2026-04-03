import SwiftUI
import Kingfisher

/// Full-screen hero banner carousel matching Apple TV design.
/// Custom page dots positioned above buttons, dark gradient, glass buttons.
struct HeroBannerView: View {
    let shows: [ShowPreview]
    let onTap: (ShowPreview) -> Void
    let onBookmark: (ShowPreview) -> Void
    let isBookmarked: (Int) -> Bool

    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Pager (hidden default indicator)
            TabView(selection: $currentPage) {
                ForEach(Array(shows.enumerated()), id: \.element.id) { index, show in
                    heroCard(show)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 520)

            // Bottom content: dots + buttons, stacked vertically
            VStack(spacing: 14) {
                // Custom page dots
                HStack(spacing: 6) {
                    ForEach(0..<shows.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? .white : .white.opacity(0.4))
                            .frame(width: index == currentPage ? 8 : 6,
                                   height: index == currentPage ? 8 : 6)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }

                // Action buttons
                if let show = shows[safe: currentPage] {
                    HStack(spacing: 12) {
                        // Discuss button - glass
                        Button {
                            onTap(show)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.right")
                                    .font(.subheadline)
                                Text("Discuss")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 11)
                            .background(AppColors.accent, in: Capsule())
                        }

                        // Add / Bookmark button - glass circle
                        Button {
                            onBookmark(show)
                        } label: {
                            Image(systemName: isBookmarked(show.id) ? "checkmark" : "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Hero Card

    private func heroCard(_ show: ShowPreview) -> some View {
        ZStack(alignment: .bottom) {
            // Backdrop image - full bleed
            Group {
                if let backdropPath = show.backdropPath,
                   let url = APIConfig.backdropHeroURL(backdropPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                } else if let posterPath = show.posterPath,
                          let url = APIConfig.posterDetailURL(posterPath) {
                    KFImage(url)
                        .resizable()
                        .placeholder { ShimmerView() }
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // Dark bottom gradient
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.15), location: 0.4),
                    .init(color: .black.opacity(0.6), location: 0.7),
                    .init(color: .black.opacity(0.9), location: 0.9),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)

            // Title + metadata (positioned above the dots/buttons overlay)
            VStack(spacing: 8) {
                Text(show.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                HStack(spacing: 8) {
                    if let network = show.networks.first {
                        Text(network)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    ForEach(show.genres.prefix(2), id: \.self) { genre in
                        Text(genre)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Text("TV-MA")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(.white.opacity(0.5), lineWidth: 0.8)
                        )
                }
            }
            .padding(.bottom, 90) // Space for dots + buttons below
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Safe array subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
