import Foundation
import CoreLocation

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
    // Type 3 is Lake and type 1 is River; see USGSWaterbodyAPI for the Great Lakes rule.
    private static let supportedTypes = "(featuretype = 3 OR featuretype = 1 OR \(USGSWaterbodyAPI.greatLakesClause))"

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
        // Results are sorted by name, and unnamed waterbodies sort first. Without
        // this filter the first 100 results were all unnamed ponds, which the
        // suggestion list drops, so nearby suggestions were always empty.
        let features = try await fetch(
            whereClause: "\(supportedTypes) AND gnisidlabel IS NOT NULL",
            location: location,
            limit: 100
        )
        return sort(features, near: location)
    }

    private static func sort(
        _ suggestions: [CatchWaterbodySuggestion],
        near location: CLLocation?
    ) -> [CatchWaterbodySuggestion] {
        // Keep distinct waterbodies even when they share a display name.
        guard let location else {
            return suggestions.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
        return suggestions.sorted { lhs, rhs in
            let left = CLLocation(latitude: lhs.coordinate.latitude, longitude: lhs.coordinate.longitude)
            let right = CLLocation(latitude: rhs.coordinate.latitude, longitude: rhs.coordinate.longitude)
            return left.distance(from: location) < right.distance(from: location)
        }
    }

    private static func fetch(
        whereClause: String,
        location: CLLocation?,
        limit: Int
    ) async throws -> [CatchWaterbodySuggestion] {
        var items = [
            URLQueryItem(name: "where", value: whereClause),
            URLQueryItem(name: "resultRecordCount", value: String(limit)),
            URLQueryItem(name: "orderByFields", value: "gnisidlabel ASC")
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

        let features = try await USGSWaterbodyAPI.query(items, timeout: 20)

        return features.compactMap { feature in
            guard
                let id = feature.attributes.id3dhp,
                let name = feature.attributes.gnisidlabel,
                !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let coordinate = USGSWaterbodyAPI.meanCoordinate(of: feature.outerBoundary)
            else { return nil }

            return CatchWaterbodySuggestion(
                id: id,
                name: name,
                kind: feature.attributes.featuretypelabel ?? "Waterbody",
                coordinate: coordinate,
                areaSquareKilometers: feature.attributes.areasqkm,
                featureType: feature.attributes.featuretype
            )
        }
    }
}
