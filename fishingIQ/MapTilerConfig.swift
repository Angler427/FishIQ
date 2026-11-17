
import Foundation

enum MapTilerConfig {

    // Paste your MapTiler key between the quotes.
    static let apiKey = "2hwY20nnpK0d3pIN7NH3"

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

Key	Description	Action
2hwY20nnpK0d3pIN7NH3
