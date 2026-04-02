import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                stops: [
                    .init(color: Color(.systemGray5), location: max(0, phase - 0.3)),
                    .init(color: Color(.systemGray4), location: phase),
                    .init(color: Color(.systemGray5), location: min(1, phase + 0.3))
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 2
                }
            }
        }
    }
}

// MARK: - Convenience modifiers

extension View {
    func shimmerPlaceholder(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        ShimmerView()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
