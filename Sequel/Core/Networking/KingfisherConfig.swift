import Kingfisher

enum KingfisherConfig {
    static func configure() {
        let cache = ImageCache.default

        // Memory: 50MB
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024

        // Disk: 200MB, 7-day TTL
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)
    }
}
