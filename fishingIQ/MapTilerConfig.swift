import Foundation

enum MapTilerConfig {

    // The key lives in Secrets.swift, which is git-ignored.
    // Copy Config/Secrets.swift.example to fishingIQ/Secrets.swift and paste your key there.
    static let apiKey = Secrets.mapTilerAPIKey

    enum Style: String {
        case outdoor = "outdoor-v4"
        case satellite = "satellite-v4"
    }

    static func styleURL(for style: Style) -> URL {
        var components = URLComponents(
            string: "https://api.maptiler.com/maps/\(style.rawValue)/style.json"
        )!

        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]

        return components.url!
    }
}
