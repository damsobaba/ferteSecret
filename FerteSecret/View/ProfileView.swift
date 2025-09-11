// ProfileView.swift
import SwiftUI
import AVFoundation

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

    // master password (insecure - ok for dev)
    private let MASTER_PASSWORD = "ava"

    // leaderboard sheet
    @State private var showLeaderboard = false
    @State private var selectedPlayer: Player? = nil

    // visibility scheduling (hide button at specific date/time)
    @State private var isLeaderboardVisible: Bool = true
    private let visibilityTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // DateComponents for Saturday 13 Sep 2025, 21:00 local time
    private let hideDateComponents = DateComponents(
        calendar: Calendar.current,
        timeZone: TimeZone.current,
        year: 2025, month: 9, day: 11, hour: 18, minute: 0
    )
    private var hideDate: Date? { Calendar.current.date(from: hideDateComponents) }

    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // Profile header (avatar) - long press opens password modal
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 2))
                            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                            .onLongPressGesture(minimumDuration: 1.4) {
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
                            HStack {
                                Spacer()
                                Text(showSecret ? "Masquer mon secret" : "Voir mon secret")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                Spacer()
                            }
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#E286CA"), Color(hex: "#BD3993")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
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
                            HStack {
                                Spacer()
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

                        // Leaderboard button (conditionally visible)
                        if isLeaderboardVisible {
                            Button(action: {
                                withAnimation(.spring()) { showLeaderboard = true }
                            }) {
                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#E286CA"), Color(hex: "#BD3993")]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                                            .frame(width: 48, height: 48)
                                            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

                                        Image(systemName: "list.number")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading) {
                                        Text("Voir le classement")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Tous les joueurs et leurs points")
                                            .foregroundColor(Color.white.opacity(0.8))
                                            .font(.caption2)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        } else {
                            // Optionnel : message indiquant l'indisponibilité
                            Text("Classement indisponible")
                                .foregroundColor(Color.white.opacity(0.6))
                                .font(.caption)
                                .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 60)
                }
                .padding(.bottom, 32)
            }
        }
        // password sheet
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
                            adminSelectedPlayerId = vm.players.first?.id
                        } else {
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
        // admin panel sheet
        .sheet(isPresented: $showAdminPanel) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Panneau Admin")
                        .font(.title2)
                        .padding(.top)

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
        // leaderboard sheet
        .sheet(isPresented: $showLeaderboard) {
            NavigationView {
                LeaderboardView(vm: vm, selectedPlayer: $selectedPlayer)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") { showLeaderboard = false }
                        }
                    }
            }
        }
        // visibility timer + initial update
        .onAppear {
            updateLeaderboardVisibility()
        }
        .onReceive(visibilityTimer) { now in
            updateLeaderboardVisibility(now: now)
        }
    }

    // MARK: - Helpers

    private func updateLeaderboardVisibility(now: Date = Date()) {
        if let hide = hideDate {
            isLeaderboardVisible = (now < hide)
        } else {
            isLeaderboardVisible = true
        }
    }
}

// preview (optional)
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(vm: GameViewModel())
    }
}
