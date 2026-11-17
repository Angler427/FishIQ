import Foundation
import CoreLocation
import SwiftUI
import Combine
struct CatchWaterbodySuggestion: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: String
    let coordinate: CLLocationCoordinate2D
    let areaSquareKilometers: Double?
    let featureType: Int?

    static func == (lhs: CatchWaterbodySuggestion, rhs: CatchWaterbodySuggestion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Searches the same nationwide USGS 3DHP waterbody layer used by FishIQ's Lakes map.
enum CatchWaterbodySearchService {
    private static let endpoint = URL(
        string: "https://3dhp.nationalmap.gov/arcgis/rest/services/usgs_3dhp_all/MapServer/60/query"
    )!

    // Type 3 is Lake. Type 1 is River. Type 4 combines oceans and Great Lakes,
    // so only the five named Great Lakes are retained from that category.
    private static let supportedTypes = "(featuretype = 3 OR featuretype = 1 OR (featuretype = 4 AND gnisidlabel IN ('Lake Superior','Lake Michigan','Lake Huron','Lake Erie','Lake Ontario')))"

    static func search(
        named query: String,
        near location: CLLocation?
    ) async throws -> [CatchWaterbodySuggestion] {
        let escaped = query.replacingOccurrences(of: "'", with: "''")
        let whereClause = "\(supportedTypes) AND gnisidlabel IS NOT NULL AND gnisidlabel LIKE '%\(escaped)%'"
        let features = try await fetch(whereClause: whereClause, location: nil, limit: 20)
        return sort(features, near: location)
    }

    static func nearby(to location: CLLocation) async throws -> [CatchWaterbodySuggestion] {
        let features = try await fetch(
            whereClause: supportedTypes,
            location: location,
            limit: 100
        )
        return sort(features, near: location)
    }

    private static func sort(
        _ suggestions: [CatchWaterbodySuggestion],
        near location: CLLocation?
    ) -> [CatchWaterbodySuggestion] {
        let ordered: [CatchWaterbodySuggestion]
        if let location {
            ordered = suggestions.sorted { lhs, rhs in
                let left = CLLocation(latitude: lhs.coordinate.latitude, longitude: lhs.coordinate.longitude)
                let right = CLLocation(latitude: rhs.coordinate.latitude, longitude: rhs.coordinate.longitude)
                return left.distance(from: location) < right.distance(from: location)
            }
        } else {
            ordered = suggestions.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

        // Keep distinct waterbodies even when they share a display name.
        return ordered
    }

    private static func fetch(
        whereClause: String,
        location: CLLocation?,
        limit: Int
    ) async throws -> [CatchWaterbodySuggestion] {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "where", value: whereClause),
            URLQueryItem(name: "outFields", value: "id3dhp,gnisidlabel,featuretypelabel,featuretype,areasqkm"),
            URLQueryItem(name: "returnGeometry", value: "true"),
            URLQueryItem(name: "outSR", value: "4326"),
            URLQueryItem(name: "resultRecordCount", value: String(limit)),
            URLQueryItem(name: "orderByFields", value: "gnisidlabel ASC"),
            URLQueryItem(name: "f", value: "json")
        ]

        if let location {
            items += [
                URLQueryItem(
                    name: "geometry",
                    value: "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                ),
                URLQueryItem(name: "geometryType", value: "esriGeometryPoint"),
                URLQueryItem(name: "inSR", value: "4326"),
                URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
                URLQueryItem(name: "distance", value: "40000"),
                URLQueryItem(name: "units", value: "esriSRUnit_Meter")
            ]
        }

        components.queryItems = items
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ArcGISWaterbodyResponse.self, from: data)
        if let serviceError = decoded.error {
            throw NSError(
                domain: "FishIQWaterbodySearch",
                code: serviceError.code,
                userInfo: [NSLocalizedDescriptionKey: serviceError.message]
            )
        }

        return (decoded.features ?? []).compactMap { feature in
            guard
                let id = feature.attributes.id3dhp,
                let name = feature.attributes.gnisidlabel,
                !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let ring = feature.geometry?.rings.first,
                !ring.isEmpty
            else { return nil }

            let longitudeValues = ring.compactMap { $0.first }
            let latitudeValues = ring.compactMap { $0.count > 1 ? $0[1] : nil }
            guard !longitudeValues.isEmpty, !latitudeValues.isEmpty else { return nil }
            let longitude = longitudeValues.reduce(0, +) / Double(longitudeValues.count)
            let latitude = latitudeValues.reduce(0, +) / Double(latitudeValues.count)
            guard CLLocationCoordinate2DIsValid(
                CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            ) else { return nil }

            return CatchWaterbodySuggestion(
                id: id,
                name: name,
                kind: feature.attributes.featuretypelabel ?? "Waterbody",
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                areaSquareKilometers: feature.attributes.areasqkm,
                featureType: feature.attributes.featuretype
            )
        }
    }
}

private struct ArcGISWaterbodyResponse: Decodable {
    let features: [Feature]?
    let error: ServiceError?

    struct Feature: Decodable {
        let attributes: Attributes
        let geometry: Geometry?
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

    struct ServiceError: Decodable {
        let code: Int
        let message: String
    }
}

@MainActor
final class CatchLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?

    private let manager = CLLocationManager()
    private var hasRequestedLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        guard !hasRequestedLocation else { return }
        hasRequestedLocation = true

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways ||
            manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let latest = locations.last {
            location = latest
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Typing-based search still works if location permission is unavailable.
    }
}
