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

    // USGS 3DHP featuretype: 3 = lake, 1 = river, 4 = ocean/Great Lakes.
    // Type 4 is restricted to the five named Great Lakes to avoid coastal
    // ocean polygons appearing as thousands of separate lakes.
    var whereClause: String {
        let greatLakes = "(featuretype = 4 AND gnisidlabel IN ('Lake Superior','Lake Michigan','Lake Huron','Lake Erie','Lake Ontario'))"
        let supportedLakes = "(featuretype = 3 OR \(greatLakes))"

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
    private let endpoint = URL(
        string: "https://3dhp.nationalmap.gov/arcgis/rest/services/usgs_3dhp_all/MapServer/60/query"
    )!

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

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "where", value: filter.whereClause),
            URLQueryItem(name: "geometry", value: "\(minLon),\(minLat),\(maxLon),\(maxLat)"),
            URLQueryItem(name: "geometryType", value: "esriGeometryEnvelope"),
            URLQueryItem(name: "inSR", value: "4326"),
            URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
            URLQueryItem(name: "outFields", value: "id3dhp,gnisidlabel,featuretypelabel,featuretype,areasqkm"),
            URLQueryItem(name: "returnGeometry", value: "true"),
            URLQueryItem(name: "outSR", value: "4326"),
            URLQueryItem(name: "maxAllowableOffset", value: String(boundaryTolerance)),
            URLQueryItem(name: "resultRecordCount", value: "100"),
            URLQueryItem(name: "orderByFields", value: filter == .riversAndStreams ? "gnisidlabel ASC" : "areasqkm DESC"),
            URLQueryItem(name: "f", value: "json")
        ]

        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(USGSResponse.self, from: data)
        if let serviceError = decoded.error {
            throw NSError(
                domain: "FishIQ.USGSWaterbodyService",
                code: serviceError.code,
                userInfo: [NSLocalizedDescriptionKey: serviceError.message]
            )
        }

        var seenIDs = Set<String>()
        return (decoded.features ?? []).compactMap { feature in
            guard let id = feature.attributes.id3dhp,
                  seenIDs.insert(id).inserted,
                  let rings = feature.geometry?.rings,
                  let outerRing = rings.first,
                  outerRing.count >= 3 else { return nil }

            let boundary = outerRing.compactMap { point -> CLLocationCoordinate2D? in
                guard point.count >= 2 else { return nil }
                let coordinate = CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
            }
            guard boundary.count >= 3 else { return nil }

            // A simple mean gives a stable pin location without adding a costly
            // polygon-centroid calculation to every map response.
            let latitude = boundary.map(\.latitude).reduce(0, +) / Double(boundary.count)
            let longitude = boundary.map(\.longitude).reduce(0, +) / Double(boundary.count)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            return USGSWaterbody(
                id: id,
                name: feature.attributes.gnisidlabel?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? feature.attributes.gnisidlabel! : "Unnamed waterbody",
                type: feature.attributes.featuretypelabel ?? "Waterbody",
                coordinate: coordinate,
                areaSquareKilometers: feature.attributes.areasqkm,
                boundary: boundary
            )
        }
    }
}

private struct USGSResponse: Decodable {
    let features: [USGSFeature]?
    let error: USGSError?
}

private struct USGSFeature: Decodable {
    let attributes: USGSAttributes
    let geometry: USGSGeometry?
}

private struct USGSAttributes: Decodable {
    let id3dhp: String?
    let gnisidlabel: String?
    let featuretypelabel: String?
    let featuretype: Int?
    let areasqkm: Double?
}

private struct USGSGeometry: Decodable {
    let rings: [[[Double]]]
}

private struct USGSError: Decodable {
    let code: Int
    let message: String
}
