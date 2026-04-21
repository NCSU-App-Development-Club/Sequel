import Foundation

actor Debouncer {
    private var task: Task<Void, Never>?

    func debounce(delay: Duration, operation: @Sendable @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(for: delay)
                await operation()
            } catch {
                // Task cancelled — no-op
            }
        }
    }
}
