import SwiftUI

@main
struct DriverTripApp: App {
    var body: some Scene {
        WindowGroup { DriverTripRootView().preferredColorScheme(.light) }
    }
}

struct DriverTripRootView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated {
                DriverHomeView()
            } else {
                LoginView(username: $username, password: $password) {
                    // Connect only after verifying the central API contract.
                }
            }
        }
    }
}

private struct LoginView: View {
    @Binding var username: String
    @Binding var password: String
    let onSignIn: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.973, green: 0.961, blue: 0.937).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 22) {
                Spacer()
                Text("SHUTTLE VACATION").font(.system(size: 13, weight: .bold, design: .rounded)).tracking(2)
                Text("Tu ruta.\nTu operación.").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("DRIVER TRIP").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                VStack(spacing: 14) {
                    TextField("Usuario", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                    Button(action: onSignIn) {
                        Text("Entrar a Driver Trip").fontWeight(.bold)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Color(red: 0.96, green: 0.77, blue: 0.10))
                            .foregroundStyle(.black).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                Spacer()
                Text("Calidad · Comfort · Excelencia").font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }
    }
}

private struct DriverHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Sin servicios cargados",
                systemImage: "car.side",
                description: Text("Los servicios asignados aparecerán aquí al conectar DriverTrip con la API.")
            )
            .navigationTitle("Driver Trip")
        }
    }
}
