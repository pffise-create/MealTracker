@preconcurrency import CoreLocation
import Foundation
import MapKit

enum VenueResolutionError: LocalizedError {
    case permissionDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Location access is off. You can still log by photo, voice, or text."
        case .locationUnavailable: "A nearby venue could not be resolved. Fallback logging is still available."
        }
    }
}

@MainActor
final class LiveVenueResolver: NSObject, VenueResolving, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorization: LocationAuthorizationState {
        switch manager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        @unknown default: .restricted
        }
    }

    func resolveForegroundVenues() async throws -> [VenueCandidate] {
        let location = try await requestLocation()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 600,
            longitudinalMeters: 600
        )
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.prefix(4).enumerated().map { index, item in
            let coordinate: CLLocationCoordinate2D
            let subtitle: String
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                coordinate = item.location.coordinate
                subtitle = item.address?.fullAddress ?? "Near your current location"
            } else {
                coordinate = item.placemark.coordinate
                subtitle = item.placemark.title ?? "Near your current location"
            }
            #else
            coordinate = item.placemark.coordinate
            subtitle = item.placemark.title ?? "Near your current location"
            #endif
            return VenueCandidate(
                id: item.name.map { "\($0)-\(coordinate.latitude)-\(coordinate.longitude)" } ?? "venue-\(index)",
                name: item.name ?? "Nearby restaurant",
                subtitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                confidence: manager.accuracyAuthorization == .reducedAccuracy
                    ? "Approximate location"
                    : "Nearby result"
            )
        }
    }

    private func requestLocation() async throws -> CLLocation {
        switch authorization {
        case .denied, .restricted:
            throw VenueResolutionError.permissionDenied
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorized:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation?.resume(throwing: VenueResolutionError.locationUnavailable)
            self.continuation = continuation
            if authorization == .authorized {
                manager.requestLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch authorization {
        case .authorized:
            if continuation != nil { manager.requestLocation() }
        case .denied, .restricted:
            continuation?.resume(throwing: VenueResolutionError.permissionDenied)
            continuation = nil
        case .notDetermined:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            continuation?.resume(throwing: VenueResolutionError.locationUnavailable)
            continuation = nil
            return
        }
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
