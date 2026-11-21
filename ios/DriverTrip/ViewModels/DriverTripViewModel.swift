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

    private let api = DriverTripAPI()
    private var token: String?

    init() {
        if let saved = DriverSessionStore.read() {
            token = saved
            isAuthenticated = true
            Task { await refreshTrips() }
        }
    }

    func signIn() async {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            show("Escribe tu usuario y contraseña.", error: true)
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await api.login(username: username, password: password)
            try DriverSessionStore.save(session.accessToken)
            token = session.accessToken
            password = ""
            isAuthenticated = true
            show("Sesión iniciada correctamente.")
            await refreshTrips()
        } catch { show(error.localizedDescription, error: true) }
    }

    func refreshTrips() async {
        guard let token else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            trips = try await api.trips(token: token)
            if trips.isEmpty { show("No tienes servicios activos asignados.") }
            else { show("Servicios actualizados.") }
        } catch {
            if error is DriverTripAPIError.unauthorized { signOutLocally() }
            show(error.localizedDescription, error: true)
        }
    }

    func updateStatus(for trip: DriverTrip, to status: String, eta: Int?) async {
        guard let token else { return }
        do {
            _ = try await api.updateStatus(tripID: trip.id, status: status, etaMinutes: eta, token: token)
            show("Estado del servicio actualizado.")
            await refreshTrips()
        } catch { show(error.localizedDescription, error: true) }
    }

    func sendLocation(_ location: DriverLocationPayload, for trip: DriverTrip) async {
        guard let token else { return }
        do {
            try await api.updateLocation(tripID: trip.id, location: location, token: token)
            show("Ubicación compartida con operaciones.")
        } catch { show(error.localizedDescription, error: true) }
    }

    func signOut() async {
        if let token { await api.logout(token: token) }
        signOutLocally()
    }

    private func signOutLocally() {
        token = nil
        trips = []
        isAuthenticated = false
        DriverSessionStore.clear()
    }

    private func show(_ text: String, error: Bool = false) {
        message = text
        isError = error
    }
}
