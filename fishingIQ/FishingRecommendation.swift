
import Foundation
import CoreLocation

struct FishingRecommendation: Identifiable {
    let id: Int
    let title: String
    let species: String
    let description: String
    let technique: String
    let depthRange: String
    let latitude: Double
    let longitude: Double
    let confidence: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
}

