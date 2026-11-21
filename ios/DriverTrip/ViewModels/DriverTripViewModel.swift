import CoreLocation
import Foundation
import Combine

@MainActor
final class DriverTripViewModel: ObservableObject {
 @Published var username = ""
 @Published var password = ""
 @Published private(set) var trips: [DriverTrip] = []
 @Published private(set) var isAuthenticated = false
 @Published private(set) var isLoading = false
 @Published private(set) var message: String?
 @Published private(set) var isError = false
 @Published private(set) var gpsMessage = "El GPS se activará automáticamente siete horas antes de tu próximo servicio."
 @Published private(set) var gpsIsActive = false
 private let api = DriverTripAPI()
 private let locationManager = DriverLocationManager()
 private var token: String?

 init() {
  locationManager.onLocationUpdate = { [weak self] location in
   guard let self, self.isAuthenticated, self.hasEligibleTrip else { return }
   Task { await self.sendLocation(location) }
  }
  locationManager.onAuthorizationChange = { [weak self] in self?.configureLocationTracking() }
  if let saved = DriverSessionStore.read() {
   token = saved; isAuthenticated = true
   Task { await refreshTrips() }
  }
 }
 private var hasEligibleTrip: Bool {
  let now = Date()
  return trips.contains { !$0.status.isClosed && now >= $0.scheduledAt.addingTimeInterval(-7 * 3600) }
 }
 func signIn() async {
  guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else { show("Escribe tu usuario y contraseña.", error: true); return }
  isLoading = true; defer { isLoading = false }
  do {
   let session = try await api.login(username: username, password: password)
   try DriverSessionStore.save(session.accessToken); token = session.accessToken; password = ""
   isAuthenticated = true; show("Sesión iniciada correctamente."); await refreshTrips()
  } catch { show(error.localizedDescription, error: true) }
 }
 func refreshTrips() async {
  guard let token else { return }
  isLoading = true; defer { isLoading = false }
  do {
   trips = try await api.trips(token: token); configureLocationTracking()
   if trips.isEmpty { show("No tienes servicios activos asignados.") } else { show("Servicios actualizados.") }
  } catch {
   if let apiError = error as? DriverTripAPIError, case .unauthorized = apiError { signOutLocally() }
   show(error.localizedDescription, error: true)
  }
 }
 private func configureLocationTracking() {
  guard isAuthenticated else { locationManager.stopAllTracking(); return }
  let eligible = hasEligibleTrip
  locationManager.monitorAssignedTrips(windowOpen: eligible, hasTrips: !trips.isEmpty)
  gpsIsActive = eligible && locationManager.isActivelyTracking
  if trips.isEmpty { gpsMessage = "No hay servicios asignados. El GPS está detenido." }
  else if eligible {
   gpsMessage = gpsIsActive ? "GPS automático activo. Se comparte con todos tus servicios dentro de la ventana autorizada." : (locationManager.lastError ?? "Servicio dentro de la ventana GPS. Autoriza Ubicación: Siempre.")
  } else {
   let next = trips.map { $0.scheduledAt.addingTimeInterval(-7 * 3600) }.filter { $0 > Date() }.min()
   gpsMessage = next.map { "GPS programado desde \($0.formatted(date: .abbreviated, time: .shortened))." } ?? "No hay servicios dentro de la ventana de seguimiento."
  }
 }
 func updateStatus(for trip: DriverTrip, to status: String, eta: Int?) async {
  guard let token else { return }
  do { _ = try await api.updateStatus(tripID: trip.id, status: status, etaMinutes: eta, token: token); show("Estado del servicio actualizado."); await refreshTrips() }
  catch { show(error.localizedDescription, error: true) }
 }
 private func sendLocation(_ location: CLLocation) async {
  guard let token, hasEligibleTrip else { return }
  let payload = DriverLocationPayload(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, accuracy: location.horizontalAccuracy)
  do {
   let response = try await api.updateDriverLocation(payload, token: token)
   gpsMessage = "Ubicación compartida con \(response.updatedServices) servicio(s) · \(Date().formatted(date: .omitted, time: .shortened))."
   gpsIsActive = true
  } catch {
   if let apiError = error as? DriverTripAPIError, case .unauthorized = apiError { signOutLocally() }
   else { gpsMessage = error.localizedDescription }
  }
 }
 func signOut() async { if let token { await api.logout(token: token) }; signOutLocally() }
 private func signOutLocally() {
  locationManager.stopAllTracking(); token = nil; trips = []; isAuthenticated = false; gpsIsActive = false
  DriverSessionStore.clear()
 }
 private func show(_ text: String, error: Bool = false) { message = text; isError = error }
}

private extension String {
 var isClosed: Bool { self == "completed" || self == "cancelled" }
}
