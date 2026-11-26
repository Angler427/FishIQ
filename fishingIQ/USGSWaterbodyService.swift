import Foundation
import CoreLocation
import MapKit

enum WaterbodyFilter: String, CaseIterable, Identifiable {
    case all, large, medium, small, riversAndStreams

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All Lakes"
        case .large: return "Large Lakes"
        case .medium: return "Medium Lakes"
        case .small: return "Small Lakes"
        case .riversAndStreams: return "Rivers & Streams"
        }
    }

    // USGS 3DHP featuretype: 3 = lake, 1 = river (see USGSWaterbodyAPI).
    var whereClause: String {
        let supportedLakes = "(featuretype = 3 OR \(USGSWaterbodyAPI.greatLakesClause))"

        switch self {
        case .all:
            return "\(supportedLakes) AND areasqkm IS NOT NULL"
        case .large:
            return "\(supportedLakes) AND areasqkm >= 5"
        case .medium:
            return "\(supportedLakes) AND areasqkm >= 0.1 AND areasqkm < 5"
        case .small:
            return "\(supportedLakes) AND areasqkm >= 0 AND areasqkm < 0.1"
        case .riversAndStreams:
            return "featuretype = 1"
        }
    }
}

struct USGSWaterbody: Identifiable {
    let id: String
    let name: String
    let type: String
    let coordinate: CLLocationCoordinate2D
    let areaSquareKilometers: Double?
    let boundary: [CLLocationCoordinate2D]
}

final class USGSWaterbodyService {
    func fetchWaterbodies(
        in region: MKCoordinateRegion,
        filter: WaterbodyFilter = .all
    ) async throws -> [USGSWaterbody] {
        let zoom = region.span.latitudeDelta
        let boundaryTolerance = max(0.00001, zoom / 300)
        let halfLat = region.span.latitudeDelta / 2
        let halfLon = region.span.longitudeDelta / 2
        let minLat = max(-90, region.center.latitude - halfLat)
        let maxLat = min(90, region.center.latitude + halfLat)
        let minLon = max(-180, region.center.longitude - halfLon)
        let maxLon = min(180, region.center.longitude + halfLon)

        let features = try await USGSWaterbodyAPI.query([
            URLQueryItem(name: "where", value: filter.whereClause),
            URLQueryItem(name: "geometry", value: "\(minLon),\(minLat),\(maxLon),\(maxLat)"),
            URLQueryItem(name: "geometryType", value: "esriGeometryEnvelope"),
            URLQueryItem(name: "inSR", value: "4326"),
            URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
            URLQueryItem(name: "maxAllowableOffset", value: String(boundaryTolerance)),
            URLQueryItem(name: "resultRecordCount", value: "100"),
            URLQueryItem(name: "orderByFields", value: filter == .riversAndStreams ? "gnisidlabel ASC" : "areasqkm DESC")
        ], timeout: 25)

        var seenIDs = Set<String>()
        return features.compactMap { feature in
            guard let id = feature.attributes.id3dhp,
                  seenIDs.insert(id).inserted else { return nil }

            let boundary = feature.outerBoundary
            guard boundary.count >= 3,
                  let coordinate = USGSWaterbodyAPI.meanCoordinate(of: boundary) else { return nil }

            let trimmedName = feature.attributes.gnisidlabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return USGSWaterbody(
                id: id,
                name: trimmedName.isEmpty ? "Unnamed waterbody" : feature.attributes.gnisidlabel!,
                type: feature.attributes.featuretypelabel ?? "Waterbody",
                coordinate: coordinate,
                areaSquareKilometers: feature.attributes.areasqkm,
                boundary: boundary
            )
        }
    }
}
