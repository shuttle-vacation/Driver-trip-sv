import Combine
import CoreLocation
import Foundation

@MainActor
final class DriverLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
 @Published private(set) var authorizationStatus: CLAuthorizationStatus
 @Published private(set) var latestLocation: CLLocation?
 @Published private(set) var lastError: String?
 @Published private(set) var isActivelyTracking = false
 var onLocationUpdate: ((CLLocation) -> Void)?
 var onAuthorizationChange: (() -> Void)?
 private let manager = CLLocationManager()
 private var hasAssignedTrips = false
 private var serviceWindowIsOpen = false
 private var significantChangeMonitoring = false

 override init() {
  authorizationStatus = manager.authorizationStatus
  super.init()
  manager.delegate = self
  manager.desiredAccuracy = kCLLocationAccuracyBest
  manager.distanceFilter = 25
  manager.activityType = .automotiveNavigation
 }

 func monitorAssignedTrips(windowOpen: Bool, hasTrips: Bool) {
  hasAssignedTrips = hasTrips; serviceWindowIsOpen = windowOpen
  guard hasTrips else { stopAllTracking(); return }
  guard CLLocationManager.locationServicesEnabled() else { lastError = "Activa los servicios de ubicación del dispositivo."; return }
  switch authorizationStatus {
  case .notDetermined: manager.requestAlwaysAuthorization()
  case .authorizedAlways:
   beginSignificantChangeMonitoring(); applyServiceWindow()
  case .authorizedWhenInUse:
   if windowOpen {
    manager.allowsBackgroundLocationUpdates = false; manager.startUpdatingLocation(); isActivelyTracking = true
    lastError = "GPS activo en primer plano. Autoriza Ubicación: Siempre para seguimiento en segundo plano."
   } else { manager.stopUpdatingLocation(); isActivelyTracking = false; lastError = "Autoriza Ubicación: Siempre para activar el GPS automático en segundo plano." }
  case .denied, .restricted: lastError = "Permiso de ubicación denegado. Actívalo en Ajustes para usar el GPS automático."
  @unknown default: lastError = "No se pudo determinar el permiso de ubicación."
  }
 }
 func stopAllTracking() {
  hasAssignedTrips = false; serviceWindowIsOpen = false
  manager.stopUpdatingLocation()
  if significantChangeMonitoring { manager.stopMonitoringSignificantLocationChanges(); significantChangeMonitoring = false }
  manager.allowsBackgroundLocationUpdates = false; isActivelyTracking = false
 }
 private func beginSignificantChangeMonitoring() {
  guard !significantChangeMonitoring, CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
  manager.startMonitoringSignificantLocationChanges(); significantChangeMonitoring = true
 }
 private func applyServiceWindow() {
  guard hasAssignedTrips, authorizationStatus == .authorizedAlways else { return }
  if serviceWindowIsOpen {
   manager.allowsBackgroundLocationUpdates = true; manager.pausesLocationUpdatesAutomatically = false
   manager.startUpdatingLocation(); isActivelyTracking = true; lastError = nil
  } else {
   manager.stopUpdatingLocation(); manager.allowsBackgroundLocationUpdates = false; isActivelyTracking = false; lastError = nil
  }
 }
 func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
  authorizationStatus = manager.authorizationStatus; onAuthorizationChange?()
 }
 func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
  guard let location = locations.last else { return }
  latestLocation = location; lastError = nil; onLocationUpdate?(location)
 }
 func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { lastError = error.localizedDescription }
}
