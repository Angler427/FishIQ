
import Foundation

// MARK: - Waterbody

enum WaterbodyType: String, Codable {
    case lake
    case reservoir
    case pond
    case river
    case stream
    case other
}

struct LakeRecord: Identifiable, Codable {
    let id: String
    var name: String
    var stateCode: String
    var county: String?

    var waterbodyType: WaterbodyType

    var latitude: Double
    var longitude: Double

    var areaAcres: Double?
    var shorelineMiles: Double?

    // Optional link to actual mapped boundary data
    var boundaryGeoJSON: String?

    var sourceID: String
    var lastVerified: Date?
}

// MARK: - Species evidence

enum SpeciesEvidenceType: String, Codable {
    case fishSurvey
    case stocking
    case verifiedObservation
    case regionalRange
}

enum DataConfidence: String, Codable {
    case high
    case medium
    case low
}

struct LakeSpeciesRecord: Identifiable, Codable {
    let id: String

    var lakeID: String
    var commonName: String
    var scientificName: String?

    var evidenceType: SpeciesEvidenceType
    var confidence: DataConfidence

    var observedDate: Date?
    var sourceID: String
    var notes: String?
}

// MARK: - Bathymetry

struct BathymetryRecord: Identifiable, Codable {
    let id: String

    var lakeID: String
    var sourceID: String

    var surveyDate: Date?

    var minimumDepthFeet: Double?
    var maximumDepthFeet: Double?

    // Links to actual contour or depth-grid data
    var contourDataURL: URL?
    var rasterDataURL: URL?

    var coverageDescription: String?
}

// MARK: - Data sources

struct LakeDataSource: Identifiable, Codable {
    let id: String

    var agency: String
    var datasetName: String

    var url: URL
    var license: String?
    var citation: String?

    var accessedAt: Date
}

