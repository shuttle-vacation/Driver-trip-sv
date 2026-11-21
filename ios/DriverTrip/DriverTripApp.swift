import SwiftUI

@main
struct DriverTripApp: App {
    var body: some Scene {
        WindowGroup { DriverTripRootView().preferredColorScheme(.light) }
    }
}

private struct DriverTripRootView: View {
    @StateObject private var model = DriverTripViewModel()

    var body: some View {
        Group {
            if model.isAuthenticated {
                DriverHomeView(model: model)
            } else {
                LoginView(model: model)
            }
        }
    }
}

private struct LoginView: View {
    @ObservedObject var model: DriverTripViewModel

    var body: some View {
        ZStack {
            Color(red: 0.973, green: 0.961, blue: 0.937).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 22) {
                Spacer()
                Text("SHUTTLE VACATION")
                    .font(.system(size: 13, weight: .bold, design: .rounded)).tracking(2)
                Text("Tu ruta.\nTu operación.")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text("DRIVER TRIP").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                VStack(spacing: 14) {
                    TextField("Usuario", text: $model.username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    SecureField("Contraseña", text: $model.password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await model.signIn() }
                    } label: {
                        HStack {
                            if model.isLoading { ProgressView().tint(.black) }
                            Text("Entrar a Driver Trip").fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(Color(red: 0.96, green: 0.77, blue: 0.10))
                        .foregroundStyle(.black).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(model.isLoading)
                }
                if let message = model.message {
                    Text(message).font(.footnote)
                        .foregroundStyle(model.isError ? .red : .secondary)
                }
                Spacer()
                Text("Calidad · Comfort · Excelencia").font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }
    }
}

private struct DriverHomeView: View {
    @ObservedObject var model: DriverTripViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Ubicación GPS") {
                    Label(model.gpsMessage, systemImage: model.gpsIsActive ? "location.fill" : "location")
                        .font(.footnote)
                        .foregroundStyle(model.gpsIsActive ? .green : .secondary)
                    Text("El seguimiento se habilita desde siete horas antes de cada servicio asignado. No necesitas elegir un traslado.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MIS TRASLADOS").font(.caption.bold()).tracking(1.2).foregroundStyle(.secondary)
                            Text("\(model.trips.count) servicios activos").font(.headline)
                        }
                        Spacer()
                        Button { Task { await model.refreshTrips() } } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Actualizar servicios")
                    }
                }
                if model.trips.isEmpty {
                    ContentUnavailableView(
                        "Sin servicios asignados",
                        systemImage: "car.side",
                        description: Text("Cuando operaciones te asigne un traslado, aparecerá aquí.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(model.trips) { trip in
                        DriverTripCard(trip: trip, model: model)
                    }
                }
                if let message = model.message {
                    Section("Estado") {
                        Text(message).foregroundStyle(model.isError ? .red : .secondary)
                    }
                }
                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        Task { await model.signOut() }
                    }
                }
            }
            .navigationTitle("Driver Trip")
            .refreshable { await model.refreshTrips() }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    if !Task.isCancelled && model.isAuthenticated { await model.refreshTrips() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.isLoading { ProgressView() }
                }
            }
        }
    }
}

private struct DriverTripCard: View {
    let trip: DriverTrip
    @ObservedObject var model: DriverTripViewModel
    @State private var selectedStatus = ""
    @State private var etaText = ""

    private let transitions: [String: [String]] = [
        "confirmed": ["assigned", "cancelled"],
        "assigned": ["driver_on_way", "cancelled", "confirmed"],
        "driver_on_way": ["driver_arrived", "incident"],
        "driver_arrived": ["passenger_onboard", "incident"],
        "passenger_onboard": ["in_transit", "incident"],
        "in_transit": ["completed", "incident"],
        "incident": ["driver_on_way", "driver_arrived", "passenger_onboard", "in_transit", "completed"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(trip.folio).font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                Spacer()
                Text(DriverTripStatus.labels[trip.status] ?? trip.status)
                    .font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.22)).clipShape(Capsule())
            }
            Text(trip.destination).font(.title3.bold())
            Label(trip.passengerName, systemImage: "person")
            Label("\(trip.passengers) pasajero(s)", systemImage: "person.2")
            Label(trip.pickup, systemImage: "mappin.and.ellipse")
            Label(trip.scheduledAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            Label("Vuelo \(trip.flightNumber)", systemImage: "airplane")
            Divider()
            if let options = transitions[trip.status], !options.isEmpty {
                Picker("Nuevo estado", selection: $selectedStatus) {
                    Text("Selecciona estado").tag("")
                    ForEach(options, id: \.self) { status in
                        Text(DriverTripStatus.labels[status] ?? status).tag(status)
                    }
                }
                TextField("ETA en minutos (opcional)", text: $etaText)
                    .keyboardType(.numberPad)
                Button("Guardar actualización") {
                    let eta = Int(etaText)
                    Task { await model.updateStatus(for: trip, to: selectedStatus, eta: eta) }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.96, green: 0.77, blue: 0.10))
                .foregroundStyle(.black)
                .disabled(selectedStatus.isEmpty || (etaText.isEmpty == false && Int(etaText) == nil))
            } else {
                Text("No hay más cambios de estado disponibles.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            if selectedStatus.isEmpty { selectedStatus = transitions[trip.status]?.first ?? "" }
            if let eta = trip.etaMinutes { etaText = String(eta) }
        }
    }
}
