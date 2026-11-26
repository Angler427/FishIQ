
import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var errorMessage: String?
    @Published var isLoading = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        errorMessage = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            isLoading = true
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            isLoading = true
            manager.requestLocation()

        case .denied, .restricted:
            errorMessage = "Location access is disabled. Enable it in Settings."

        @unknown default:
            errorMessage = "Unable to determine location permission."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()

        case .denied, .restricted:
            isLoading = false
            errorMessage = "Location permission was denied."

        case .notDetermined:
            break

        @unknown default:
            isLoading = false
            errorMessage = "Unknown location permission status."
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latestLocation = locations.last else {
            isLoading = false
            errorMessage = "Couldn't find your location."
            return
        }

        location = latestLocation
        isLoading = false
        errorMessage = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        isLoading = false
        errorMessage = error.localizedDescription
    }
}

