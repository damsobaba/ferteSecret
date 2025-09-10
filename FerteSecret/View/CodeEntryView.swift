import SwiftUI
import ConfettiSwiftUI
import AVFoundation

// NOTE: ce fichier suppose que tu as déjà défini ailleurs:
// - GradientBackground
// - ShakeEffect
// - PrimaryButtonStyle & GhostButtonStyle (ou tu peux garder ceux que tu as)
// - GameViewModel (avec Player.id : String)

struct CodeEntryView: View {
    @ObservedObject var vm: GameViewModel

    // animations & feedback
    @State private var shakeButton = 0
    @State private var showSuccess = false
    @State private var confettiTrigger = false

    // pickers : Player.id est de type String (docId)
    @State private var selectedPlayerID: String?
    @State private var selectedSecret = ""

    // sheet + search
    @State private var showSecretSheet = false
    @State private var secretSearch = ""

    // Ajuste ce nombre pour remonter / descendre tout
    private let topOffset: CGFloat = 50

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: topOffset)

                ScrollView {
                    VStack(spacing: 16) {
                        HeaderView()

                        titleSection

                        pointsView

                        playerSection

                        secretSection

                        actionsSection

                        if !vm.message.isEmpty {
                            Text(vm.message)
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }
                .confettiCannon(trigger: $confettiTrigger, num: 100, rainHeight: 600, repetitions: 1)
            }
            .ignoresSafeArea(edges: .top)
        }
        .sheet(isPresented: $showSecretSheet) {
            secretSelectionSheet
        }
        .alert("Bravo !", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Vous avez trouvé le secret et gagné 3 points ! 🎉")
        }
        .onAppear {
            // init selection safely
            selectedPlayerID = vm.players.first(where: { $0.id != vm.currentPlayer?.id })?.id
            selectedSecret = vm.availableSecrets.first ?? ""
        }
    }

    // MARK: - Sections / Subviews

    private var titleSection: some View {
        Text("Trouve le secret")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 6)
    }

    private var pointsView: some View {
        HStack {
            Text("Points")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text("\(vm.currentPlayer?.points ?? 0)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choisir un joueur")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            NamePickerView(players: vm.players, selectedId: $selectedPlayerID, excludeCurrentId: vm.currentPlayer?.id)
                .padding(.horizontal)
        }
    }

    private var secretSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choisir un secret")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            Button {
                showSecretSheet.toggle()
            } label: {
                HStack {
                    Text(selectedSecret.isEmpty ? "Sélectionner un secret" : selectedSecret)
                        .foregroundColor(selectedSecret.isEmpty ? Color.white.opacity(0.7) : .white)
                    Spacer()
                    if !selectedSecret.isEmpty {
                        Text("choisi")
                            .font(.caption2)
                            .padding(6)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: validateGuess) {
                Text("Valider")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(gradient: Gradient(colors: [ Color(hex: "#E286CA"), Color(hex: "#BD3993") ]),
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
            }
            .disabled(selectedPlayerID == nil || selectedSecret.isEmpty)
            .modifier(ShakeEffect(shakes: CGFloat(shakeButton)))
            .padding(.horizontal)

            Button(action: clearMessage) {
                Text("Effacer")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Secret sheet (searchable)
    private var secretSelectionSheet: some View {
        NavigationView {
            List {
                ForEach(filteredSecrets(), id: \.self) { secret in
                    Button {
                        selectedSecret = secret
                        secretSearch = ""
                        showSecretSheet = false
                    } label: {
                        HStack {
                            Text(secret)
                            Spacer()
                            if vm.players.contains(where: { $0.secret == secret }) {
                                Text("attribué")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(6)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(8)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("Choisir un secret")
            .searchable(text: $secretSearch, placement: .navigationBarDrawer(displayMode: .always), prompt: "Rechercher un secret")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        showSecretSheet = false
                        secretSearch = ""
                    }
                }
            }
        }
    }

    // MARK: - Logic
    private func filteredSecrets() -> [String] {
        if secretSearch.isEmpty { return vm.availableSecrets }
        return vm.availableSecrets.filter { $0.localizedCaseInsensitiveContains(secretSearch) }
    }

    private func validateGuess() {
        guard let id = selectedPlayerID,
              let target = vm.players.first(where: { $0.id == id }),
              let me = vm.currentPlayer else { return }

        guard let targetSecret = target.secret else {
            vm.message = "Ce joueur n'a pas encore choisi son secret."
            return
        }

        if selectedSecret == targetSecret {
            vm.message = ""
            var p = me; p.points += 3; vm.updatePlayer(p)
            AudioServicesPlaySystemSound(1025)
            confettiTrigger.toggle()
            showSuccess = true
            // success
            vm.changePointsForCurrentPlayer(by: 3) { ok, err in
                if ok {
                    // confetti / son / alert
                } else {
                    print("Erreur incrément points:", err ?? "")
                }
            }


        } else {
            var p = me; p.points = max(0, p.points - 1); vm.updatePlayer(p)
            vm.message = "Mauvais secret !"
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 5)
                          .repeatCount(3, autoreverses: false)) {
                shakeButton += 1
            }
            // failure (perdre 1 point)
            vm.changePointsForCurrentPlayer(by: -1) { ok, err in
                if !ok { print("Erreur décrément:", err ?? "") }
                // lance shake etc
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        // optional: keep selection or reset
        selectedSecret = vm.availableSecrets.first ?? ""
    }

    private func clearMessage() {
        vm.message = ""
    }
}

// MARK: - Small subviews to help the compiler

private struct HeaderView: View {
    var body: some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)

                Image("eye")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

import SwiftUI

struct NamePickerView: View {
    let players: [Player]
    @Binding var selectedId: String?
    var excludeCurrentId: String? = nil

    private var list: [Player] {
        if let exclude = excludeCurrentId {
            return players.filter { $0.id != exclude }
        }
        return players
    }

    var body: some View {
        Menu {
            if list.isEmpty {
                Button("Aucun joueur") { }
            } else {
                ForEach(list, id: \.id) { p in
                    Button {
                        selectedId = p.id
                    } label: {
                        HStack {
                            Text(p.username)
                            Spacer()
                            if p.secret != nil { Text("🔐") }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(players.first(where: { $0.id == selectedId })?.username ?? "Choisir un joueur")
                    .foregroundColor(selectedId == nil ? Color.white.opacity(0.7) : .white)
                Spacer()
                Image(systemName: "person.fill").foregroundColor(.white.opacity(0.9))
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
        }
    }
}
