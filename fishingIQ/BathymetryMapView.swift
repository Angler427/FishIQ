import SwiftUI
import MapKit
import UIKit

/// MapKit-backed map so the county bathymetry raster can be rendered as a real
/// georeferenced tile overlay above the basemap and below lake annotations.
struct BathymetryMapView: UIViewRepresentable {
    @Binding private var region: MKCoordinateRegion
    private var annotations: [LakeMapPin]
    private var onSelect: ((LakeMapPin) -> Void)?
    private var regionIsMutable: Bool

    /// Keeps the existing lake-profile preview call sites working.
    init(initialRegion: MKCoordinateRegion) {
        self._region = .constant(initialRegion)
        self.annotations = []
        self.onSelect = nil
        self.regionIsMutable = false
    }

    /// Main interactive Lakes map initializer.
    init(
        region: Binding<MKCoordinateRegion>,
        annotations: [LakeMapPin],
        onSelect: ((LakeMapPin) -> Void)? = nil
    ) {
        self._region = region
        self.annotations = annotations
        self.onSelect = onSelect
        self.regionIsMutable = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        mapView.mapType = .standard
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .includingAll

        let bathymetry = WaukeshaBathymetryTileOverlay()
        bathymetry.canReplaceMapContent = false
        mapView.addOverlay(bathymetry, level: .aboveRoads)

        syncAnnotations(on: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        if Self.regionNeedsUpdate(mapView.region, region) {
            mapView.setRegion(region, animated: true)
        }
        syncAnnotations(on: mapView)
    }

    private func syncAnnotations(on mapView: MKMapView) {
        let existing = mapView.annotations.compactMap { $0 as? LakeMapAnnotation }
        let wantedIDs = Set(annotations.map(\.id))

        for annotation in existing where !wantedIDs.contains(annotation.pin.id) {
            mapView.removeAnnotation(annotation)
        }

        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.pin.id, $0) })
        var additions: [LakeMapAnnotation] = []
        for pin in annotations {
            if let annotation = existingByID[pin.id] {
                annotation.pin = pin
                annotation.coordinate = pin.coordinate
            } else {
                additions.append(LakeMapAnnotation(pin: pin))
            }
        }
        if !additions.isEmpty { mapView.addAnnotations(additions) }
    }

    private static func regionNeedsUpdate(_ current: MKCoordinateRegion, _ target: MKCoordinateRegion) -> Bool {
        abs(current.center.latitude - target.center.latitude) > 0.0001 ||
        abs(current.center.longitude - target.center.longitude) > 0.0001 ||
        abs(current.span.latitudeDelta - target.span.latitudeDelta) > 0.0001 ||
        abs(current.span.longitudeDelta - target.span.longitudeDelta) > 0.0001
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: BathymetryMapView

        init(parent: BathymetryMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let tileOverlay = overlay as? MKTileOverlay else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
            renderer.alpha = 0.94
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let lakeAnnotation = annotation as? LakeMapAnnotation else { return nil }
            let identifier = "FishIQLakePin"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true
            view.markerTintColor = lakeAnnotation.pin.recommendationID != nil ? .systemOrange : .systemBlue
            view.glyphImage = UIImage(systemName: lakeAnnotation.pin.recommendationID != nil ? "mappin.and.ellipse" : "water.waves")
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? LakeMapAnnotation else { return }
            parent.onSelect?(annotation.pin)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if parent.regionIsMutable {
                parent.region = mapView.region
            }
        }
    }
}

private final class LakeMapAnnotation: NSObject, MKAnnotation {
    var pin: LakeMapPin
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { pin.name }

    init(pin: LakeMapPin) {
        self.pin = pin
        self.coordinate = pin.coordinate
        super.init()
    }
}

/// Waukesha County's bathymetry ImageServer is stored in NAD27 Wisconsin
/// South State Plane (WKID 103191). The server reprojects each request to
/// Web Mercator (WKID 3857), which is the projection MapKit uses for tiles.
final class WaukeshaBathymetryTileOverlay: MKTileOverlay {
    private let imageServiceURL = URL(
        string: "https://gis.waukeshacounty.gov/image/rest/services/RASTER/WaukeshaBathymetry/ImageServer/exportImage"
    )!

    override init(urlTemplate: String?) {
        super.init(urlTemplate: nil)
        canReplaceMapContent = false
        minimumZ = 6
        maximumZ = 19
        tileSize = CGSize(width: 256, height: 256)
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let tileCount = pow(2.0, Double(path.z))
        let west = Double(path.x) / tileCount * 360.0 - 180.0
        let east = Double(path.x + 1) / tileCount * 360.0 - 180.0
        let northRadians = atan(sinh(.pi * (1.0 - 2.0 * Double(path.y) / tileCount)))
        let southRadians = atan(sinh(.pi * (1.0 - 2.0 * Double(path.y + 1) / tileCount)))
        let north = northRadians * 180.0 / .pi
        let south = southRadians * 180.0 / .pi

        let bbox = [west, south, east, north]
            .map { String(format: "%.9f", locale: Locale(identifier: "en_US_POSIX"), $0) }
            .joined(separator: ",")

        var components = URLComponents(url: imageServiceURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "bbox", value: bbox),
            URLQueryItem(name: "bboxSR", value: "4326"),
            // Critical alignment fix: MapKit tile images must be returned in Web Mercator.
            URLQueryItem(name: "imageSR", value: "3857"),
            URLQueryItem(name: "size", value: "256,256"),
            URLQueryItem(name: "format", value: "png32"),
            URLQueryItem(name: "transparent", value: "true"),
            // The source consists of scanned DNR map sheets. Treat pure white
            // paper as NoData so the basemap remains visible around the lake.
            URLQueryItem(name: "noData", value: "255,255,255"),
            URLQueryItem(name: "noDataInterpretation", value: "esriNoDataMatchAll"),
            URLQueryItem(name: "interpolation", value: "RSP_BilinearInterpolation"),
            URLQueryItem(name: "f", value: "image")
        ]
        return components.url ?? imageServiceURL
    }
}
