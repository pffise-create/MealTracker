@preconcurrency import CoreLocation
import Foundation
import MapKit

enum VenueResolutionError: LocalizedError {
    case permissionDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Location access is off. Log another way."
        case .locationUnavailable: "No nearby restaurant found. Log another way."
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
        async let restaurantItems = nearbyMapItems(matching: "restaurant", around: location)
        async let cafeItems = nearbyMapItems(matching: "cafe", around: location)
        let mapItems = await restaurantItems + cafeItems

        var seenVenueKeys = Set<String>()
        let venues = mapItems.enumerated().compactMap { index, item -> (venue: VenueCandidate, distance: CLLocationDistance)? in
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

            let name = item.name ?? "Nearby restaurant"
            let venueKey = "\(name.lowercased())|\(coordinate.latitude.rounded(toPlaces: 4))|\(coordinate.longitude.rounded(toPlaces: 4))"
            guard seenVenueKeys.insert(venueKey).inserted else { return nil }

            let venue = VenueCandidate(
                id: item.name.map { "\($0)-\(coordinate.latitude)-\(coordinate.longitude)" } ?? "venue-\(index)",
                name: name,
                subtitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                confidence: manager.accuracyAuthorization == .reducedAccuracy
                    ? "Approximate location"
                    : "Nearby result"
            )
            let distance = location.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            return (venue, distance)
        }
        return venues
            .sorted { $0.distance < $1.distance }
            .prefix(8)
            .map(\.venue)
    }

    private func nearbyMapItems(matching query: String, around location: CLLocation) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1_500,
            longitudinalMeters: 1_500
        )

        do {
            return try await MKLocalSearch(request: request).start().mapItems
        } catch {
            return []
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

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
