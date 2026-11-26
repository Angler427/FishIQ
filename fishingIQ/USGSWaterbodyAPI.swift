import Foundation
import CoreLocation

/// Shared access to the nationwide USGS 3D Hydrography Program (3DHP)
/// waterbody layer. Used by the Lakes map (`USGSWaterbodyService`) and the
/// catch-log lake search (`CatchWaterbodySearchService`).
enum USGSWaterbodyAPI {
    static let endpoint = URL(
        string: "https://3dhp.nationalmap.gov/arcgis/rest/services/usgs_3dhp_all/MapServer/60/query"
    )!

    // USGS 3DHP featuretype: 3 = lake, 1 = river, 4 = ocean/Great Lakes.
    // Type 4 is restricted to the five named Great Lakes to avoid coastal
    // ocean polygons appearing as thousands of separate lakes.
    static let greatLakesClause = "(featuretype = 4 AND gnisidlabel IN ('Lake Superior','Lake Michigan','Lake Huron','Lake Erie','Lake Ontario'))"

    /// Runs a query against the waterbody layer. The fields, output
    /// projection and format every caller needs are added here; pass only
    /// the query-specific items (where clause, geometry filter, sorting, limit).
    static func query(
        _ queryItems: [URLQueryItem],
        timeout: TimeInterval
    ) async throws -> [Feature] {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems + [
            URLQueryItem(name: "outFields", value: "id3dhp,gnisidlabel,featuretypelabel,featuretype,areasqkm"),
            URLQueryItem(name: "returnGeometry", value: "true"),
            URLQueryItem(name: "outSR", value: "4326"),
            URLQueryItem(name: "f", value: "json")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        if let serviceError = decoded.error {
            throw NSError(
                domain: "FishIQ.USGSWaterbodyAPI",
                code: serviceError.code,
                userInfo: [NSLocalizedDescriptionKey: serviceError.message]
            )
        }
        return decoded.features ?? []
    }

    /// A simple mean gives a stable pin location without adding a costly
    /// polygon-centroid calculation to every map response.
    static func meanCoordinate(of points: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D? {
        guard !points.isEmpty else { return nil }
        let latitude = points.map(\.latitude).reduce(0, +) / Double(points.count)
        let longitude = points.map(\.longitude).reduce(0, +) / Double(points.count)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }

    // MARK: - Response

    struct Feature: Decodable {
        let attributes: Attributes
        let geometry: Geometry?

        /// The valid coordinates of the polygon's outer ring, or an empty
        /// array when the feature has no geometry.
        var outerBoundary: [CLLocationCoordinate2D] {
            guard let outerRing = geometry?.rings.first else { return [] }
            return outerRing.compactMap { point in
                guard point.count >= 2 else { return nil }
                let coordinate = CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
            }
        }
    }

    struct Attributes: Decodable {
        let id3dhp: String?
        let gnisidlabel: String?
        let featuretypelabel: String?
        let featuretype: Int?
        let areasqkm: Double?
    }

    struct Geometry: Decodable {
        let rings: [[[Double]]]
    }

    private struct Response: Decodable {
        let features: [Feature]?
        let error: ServiceError?
    }

    private struct ServiceError: Decodable {
        let code: Int
        let message: String
    }
}
