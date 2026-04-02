import SwiftUI

struct ThreadView: View {
    let showId: Int
    let season: Int
    let episode: Int

    var body: some View {
        Text("Thread S\(season)E\(episode) — Coming in Sprint 3")
            .navigationTitle("S\(season)E\(episode)")
            .navigationBarTitleDisplayMode(.inline)
    }
}
