import Foundation

struct DriverTrip: Identifiable, Decodable, Sendable {
    let id: Int
    let folio: String
    let flightNumber: String
    let passengerName: String
    let destination: String
    let pickup: String
    let scheduledAt: Date
    let passengers: Int
    let status: String
    let etaMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id, folio, destination, pickup, passengers, status
        case flightNumber = "flight_number"
        case passengerName = "passenger_name"
        case scheduledAt = "scheduled_at"
        case etaMinutes = "eta_minutes"
    }
}

enum DriverTripStatus {
    static let labels: [String: String] = [
        "confirmed": "Reservación confirmada",
        "assigned": "Unidad asignada",
        "driver_on_way": "Conductor en camino",
        "driver_arrived": "Conductor llegó",
        "passenger_onboard": "Pasajero abordó",
        "in_transit": "En trayecto",
        "completed": "Servicio completado",
        "incident": "Incidencia reportada",
        "cancelled": "Servicio cancelado"
    ]
}
