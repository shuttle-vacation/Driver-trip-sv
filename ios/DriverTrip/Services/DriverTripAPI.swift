import Foundation

struct DriverLoginResponse: Decodable, Sendable {
 let accessToken: String; let tokenType: String; let expiresAt: String
 enum CodingKeys: String, CodingKey { case accessToken = "access_token", tokenType = "token_type", expiresAt = "expires_at" }
}
struct DriverLocationPayload: Encodable, Sendable { let latitude: Double; let longitude: Double; let accuracy: Double }
struct DriverLocationResponse: Decodable, Sendable {
 let ok: Bool; let updatedServices: Int; let lastLocationAt: String
 enum CodingKeys: String, CodingKey { case ok; case updatedServices = "updated_services"; case lastLocationAt = "last_location_at" }
}
enum DriverTripAPIError: LocalizedError {
 case invalidResponse, server(String), unauthorized
 var errorDescription: String? {
  switch self { case .invalidResponse: return "La API devolvió una respuesta no válida."; case .server(let message): return message; case .unauthorized: return "Tu sesión venció. Inicia sesión nuevamente." }
 }
}
struct DriverTripAPI: Sendable {
 let baseURL = URL(string: "https://api.shuttlevacation.com")!
 func login(username: String, password: String) async throws -> DriverLoginResponse {
  struct Body: Encodable { let username: String; let password: String }
  return try await request("/api/driver/login", method: "POST", body: Body(username: username, password: password), token: nil)
 }
 func trips(token: String) async throws -> [DriverTrip] {
  try await request("/api/driver/trips", method: "GET", body: Optional<String>.none, token: token)
 }
 func updateStatus(tripID: Int, status: String, etaMinutes: Int?, token: String) async throws -> DriverTrip {
  struct Body: Encodable { let status: String; let eta_minutes: Int? }
  return try await request("/api/trips/\(tripID)/status", method: "PATCH", body: Body(status: status, eta_minutes: etaMinutes), token: token)
 }
 // Server authorizes the seven-hour window and updates every eligible assigned service.
 func updateDriverLocation(_ location: DriverLocationPayload, token: String) async throws -> DriverLocationResponse {
  try await request("/api/driver/location", method: "POST", body: location, token: token)
 }
 func logout(token: String) async {
  struct EmptyBody: Encodable {}
  do { let _: [String: Bool] = try await request("/api/driver/logout", method: "POST", body: EmptyBody(), token: token) } catch {}
 }
 private func request<Response: Decodable, Body: Encodable>(_ path: String, method: String, body: Body?, token: String?) async throws -> Response {
  var request = URLRequest(url: baseURL.appendingPathComponent(String(path.dropFirst())))
  request.httpMethod = method
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue("application/json", forHTTPHeaderField: "Accept")
  if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
  if let body { request.httpBody = try JSONEncoder().encode(body) }
  let (data, response) = try await URLSession.shared.data(for: request)
  guard let http = response as? HTTPURLResponse else { throw DriverTripAPIError.invalidResponse }
  guard (200..<300).contains(http.statusCode) else {
   if http.statusCode == 401 { throw DriverTripAPIError.unauthorized }
   let detail = (try? JSONDecoder().decode(APIErrorBody.self, from: data).detail) ?? "Error de API (\(http.statusCode))."
   throw DriverTripAPIError.server(detail)
  }
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .custom { decoder in
   let container = try decoder.singleValueContainer(), raw = try container.decode(String.self)
   let formatter = ISO8601DateFormatter()
   formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
   if let date = formatter.date(from: raw) { return date }
   formatter.formatOptions = [.withInternetDateTime]
   if let date = formatter.date(from: raw) { return date }
   throw DecodingError.dataCorruptedError(in: container, debugDescription: "Fecha ISO-8601 no válida: \(raw)")
  }
  return try decoder.decode(Response.self, from: data)
 }
}
private struct APIErrorBody: Decodable { let detail: String }
