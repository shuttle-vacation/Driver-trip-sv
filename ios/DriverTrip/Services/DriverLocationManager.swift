import Combine
import CoreLocation
import Foundation

@MainActor
final class DriverLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var latestLocation: CLLocation?
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 25
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startAuthorizedTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            lastError = "Los servicios de ubicación están desactivados."
            return
        }
        guard authorizationStatus == .authorizedAlways else {
            lastError = "Se requiere autorización de ubicación Siempre para seguimiento en segundo plano."
            return
        }
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestLocation = locations.last
        lastError = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error.localizedDescription
    }
}
