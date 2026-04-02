import SwiftUI

struct ShowDetailView: View {
    let tmdbId: Int

    var body: some View {
        Text("Show Detail for \(tmdbId) — Coming in Sprint 2")
            .navigationTitle("Show")
            .navigationBarTitleDisplayMode(.inline)
    }
}
