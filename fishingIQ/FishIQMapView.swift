
import SwiftUI
import MapKit
import MapLibre

struct FishIQMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    let annotations: [LakeMapPin]
    let style: MapTilerConfig.Style
    var onSelect: ((LakeMapPin) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(
            frame: .zero,
            styleURL: MapTilerConfig.styleURL(for: style)
        )

        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompassView = true
        mapView.showsScale = true
        mapView.showsAttributionButton = true
        mapView.showsLogoView = true

        mapView.setCenter(
            region.center,
            zoomLevel: Self.zoomLevel(
                for: region,
                mapWidth: mapView.bounds.width
            ),
            animated: false
        )

        syncAnnotations(on: mapView, coordinator: context.coordinator)

        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.parent = self

        let requestedStyleURL = MapTilerConfig.styleURL(for: style)

        if mapView.styleURL != requestedStyleURL {
            mapView.styleURL = requestedStyleURL
        }

        if Self.regionNeedsUpdate(mapView, target: region) {
            mapView.setCenter(
                region.center,
                zoomLevel: Self.zoomLevel(
                    for: region,
                    mapWidth: mapView.bounds.width
                ),
                animated: true
            )
        }

        syncAnnotations(on: mapView, coordinator: context.coordinator)
    }

    private func syncAnnotations(
        on mapView: MLNMapView,
        coordinator: Coordinator
    ) {
        let wantedIDs = Set(annotations.map(\.id))

        let existing = mapView.annotations.compactMap {
            $0 as? MLNPointAnnotation
        }

        for annotation in existing {
            let objectID = ObjectIdentifier(annotation)

            guard let pinID = coordinator.annotationIDs[objectID] else {
                continue
            }

            if !wantedIDs.contains(pinID) {
                mapView.removeAnnotation(annotation)
                coordinator.annotationIDs.removeValue(forKey: objectID)
            }
        }

        let currentIDs = Set(coordinator.annotationIDs.values)

        for pin in annotations where !currentIDs.contains(pin.id) {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = pin.coordinate
            annotation.title = pin.name

            mapView.addAnnotation(annotation)

            coordinator.annotationIDs[ObjectIdentifier(annotation)] = pin.id
        }

        coordinator.pinsByID = Dictionary(
            uniqueKeysWithValues: annotations.map { ($0.id, $0) }
        )
    }

    private static func zoomLevel(
        for region: MKCoordinateRegion,
        mapWidth: CGFloat
    ) -> Double {
        let width = max(Double(mapWidth), 1)
        let longitudeSpan = max(region.span.longitudeDelta, 0.000001)

        let zoom = log2((360.0 * width / 256.0) / longitudeSpan)

        return min(max(zoom, 1), 20)
    }

    private static func regionNeedsUpdate(
        _ mapView: MLNMapView,
        target: MKCoordinateRegion
    ) -> Bool {
        abs(mapView.centerCoordinate.latitude - target.center.latitude) > 0.0001 ||
        abs(mapView.centerCoordinate.longitude - target.center.longitude) > 0.0001 ||
        abs(mapView.zoomLevel - zoomLevel(
            for: target,
            mapWidth: mapView.bounds.width
        )) > 0.05
    }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: FishIQMapView

        var annotationIDs: [ObjectIdentifier: String] = [:]
        var pinsByID: [String: LakeMapPin] = [:]

        init(parent: FishIQMapView) {
            self.parent = parent
        }

        func mapView(
            _ mapView: MLNMapView,
            didSelect annotation: MLNAnnotation
        ) {
            let objectID = ObjectIdentifier(annotation as AnyObject)

            guard
                let pinID = annotationIDs[objectID],
                let pin = pinsByID[pinID]
            else {
                return
            }

            parent.onSelect?(pin)
        }

        func mapView(
            _ mapView: MLNMapView,
            viewFor annotation: MLNAnnotation
        ) -> MLNAnnotationView? {
            let objectID = ObjectIdentifier(annotation as AnyObject)

            guard
                let pinID = annotationIDs[objectID],
                let pin = pinsByID[pinID]
            else {
                return nil
            }

            let identifier = pin.recommendationID == nil
                ? "FishIQLakePin"
                : "FishIQRecommendationPin"

            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) ?? MLNAnnotationView(reuseIdentifier: identifier)

            view.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
            view.backgroundColor = pin.recommendationID == nil
                ? .systemBlue
                : .systemOrange
            view.layer.cornerRadius = 12
            view.layer.borderWidth = 2
            view.layer.borderColor = UIColor.white.cgColor

            return view
        }

        func mapView(
            _ mapView: MLNMapView,
            annotationCanShowCallout annotation: MLNAnnotation
        ) -> Bool {
            true
        }

        func mapView(
            _ mapView: MLNMapView,
            regionDidChangeAnimated animated: Bool
        ) {
            let bounds = mapView.visibleCoordinateBounds

            let latitudeDelta = abs(
                bounds.ne.latitude - bounds.sw.latitude
            )

            let longitudeDelta = abs(
                bounds.ne.longitude - bounds.sw.longitude
            )

            guard latitudeDelta > 0, longitudeDelta > 0 else {
                return
            }

            parent.region = MKCoordinateRegion(
                center: mapView.centerCoordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        }

        func mapViewDidFailLoadingMap(
            _ mapView: MLNMapView,
            withError error: Error
        ) {
            print("FishIQ MapLibre error: \(error.localizedDescription)")
        }
    }
}

