import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: GameViewModel
    @State private var showSecret = false

    // admin hidden button states
    @State private var showPasswordSheet = false
    @State private var adminPasswordInput = ""
    @State private var showAdminPanel = false

    // admin panel fields
    @State private var adminSelectedPlayerId: String?
    @State private var adminPointsToAdd: Int = 3

    // CHANGE THIS to whatever short password you want (insecure for production)
    private let MASTER_PASSWORD = "bitch"

    var body: some View {
        ZStack {
            // full-screen gradient
            GradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // Profile header with long-press on avatar
                    VStack(spacing: 12) {
                        // avatar tappable / long press to open admin password sheet
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 2))
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                            .onLongPressGesture(minimumDuration: 1.4) {
                                // reveal password modal
                                showPasswordSheet = true
                            }

                        Text(vm.currentPlayer?.username ?? "—")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 56)

                    // Secret card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Votre secret")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.95))

                        Text(showSecret ? (vm.currentPlayer?.secret ?? "—") : "••••••••")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(showSecret ? .white : Color.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Garde-le secret — seul toi peux le voir.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // actions
                    VStack(spacing: 12) {
                        Button(action: { withAnimation { showSecret.toggle() } }) {
                            HStack { Spacer()
                                Text(showSecret ? "Masquer mon secret" : "Voir mon secret")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                Spacer()
                            }
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#E286CA"), Color(hex: "#BD3993")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        Button(action: {
                            // logout
                            vm.isLoggedIn = false
                            vm.currentPlayer = nil
                            vm.codeInput = ""
                            vm.message = ""
                        }) {
                            HStack { Spacer()
                                Text("Déconnexion")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.bottom, 32)
            }
        }
        // Password sheet (small modal)
        .sheet(isPresented: $showPasswordSheet) {
            VStack(spacing: 16) {
                Text("Mode administrateur")
                    .font(.headline)
                    .padding(.top, 8)

                SecureField("Mot de passe admin", text: $adminPasswordInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                HStack {
                    Button("Annuler") {
                        adminPasswordInput = ""
                        showPasswordSheet = false
                    }
                    Spacer()
                    Button("Valider") {
                        if adminPasswordInput == MASTER_PASSWORD {
                            adminPasswordInput = ""
                            showPasswordSheet = false
                            showAdminPanel = true
                            // preselect a player if available
                            adminSelectedPlayerId = vm.players.first?.id
                        } else {
                            // feedback for wrong password
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            adminPasswordInput = ""
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .presentationDetents([.fraction(0.28)])
        }
        // Admin panel: choose player + give points
        .sheet(isPresented: $showAdminPanel) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Panneau Admin")
                        .font(.title2)
                        .padding(.top)

                    // Player picker
                    Picker("Choisir un joueur", selection: Binding(
                        get: { adminSelectedPlayerId ?? vm.players.first?.id ?? "" },
                        set: { adminSelectedPlayerId = $0 }
                    )) {
                        ForEach(vm.players, id: \.id) { p in
                            Text(p.username).tag(p.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)

                    // Points stepper
                    Stepper("Points à ajouter : \(adminPointsToAdd)", value: $adminPointsToAdd, in: -50...100)
                        .padding(.horizontal)

                    Button(action: {
                        guard let pid = adminSelectedPlayerId else { return }
                        vm.addPoints(to: pid, amount: adminPointsToAdd)

                        showAdminPanel = false
                    }) {
                        Text("Appliquer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#E286CA"), Color(hex: "#BD3993")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { showAdminPanel = false }
                    }
                }
            }
        }
    }
}
