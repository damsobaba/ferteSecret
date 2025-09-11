import SwiftUI
import ConfettiSwiftUI
import AVFoundation

// NOTE: ce fichier suppose que tu as déjà défini ailleurs:
// - GradientBackground
// - ShakeEffect
// - PrimaryButtonStyle & GhostButtonStyle (optionnel)
// - GameViewModel (avec Player.id : String)
// - FirebaseService (avec markSecretRevealed, changePlayerPoints, fetchSecrets etc.)

struct CodeEntryView: View {
    @ObservedObject var vm: GameViewModel

    // animations & feedback
    @State private var shakeButton = 0
    @State private var showSuccess = false
    @State private var confettiTrigger = false
    @State private var animateSuccess = false

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
            Text("Vous avez trouvé le secret et gagné 5 points ! 🎉")
        }
        .onAppear {
            selectedPlayerID = vm.players.first(where: { $0.id != vm.currentPlayer?.id })?.id
            selectedSecret = vm.availableSecrets.first ?? ""
        }
        .onReceive(vm.$players) { _ in
            refreshSelectionIfNeeded()
        }
        .onReceive(vm.$availableSecrets) { secrets in
            if selectedSecret.isEmpty || !secrets.contains(selectedSecret) {
                selectedSecret = secrets.first ?? ""
            }
        }
        .onChange(of: vm.currentPlayer?.points) { _ in
            // efface messages si on veut rafraîchir l'UI après mise à jour points
            vm.message = ""
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
        VStack(alignment: .center, spacing: 8) {
            Text("Choisir un joueur")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            NamePickerView(players: vm.players, selectedId: $selectedPlayerID, excludeCurrentId: vm.currentPlayer?.id)
                .padding(.horizontal)
        }
    }

    private var secretSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Choisir un secret")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            Button {
                showSecretSheet.toggle()
            } label: {
                HStack {
                    Text(selectedSecret.isEmpty ? "Sélectionner un secret" : selectedSecret)
                        .foregroundColor(selectedSecret.isEmpty ? Color.white.opacity(0.7) : .white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
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
            // disabled also when the current player has 0 points
            .disabled(selectedPlayerID == nil || selectedSecret.isEmpty || (vm.currentPlayer?.points ?? 0) <= 0)
            .opacity((selectedPlayerID == nil || selectedSecret.isEmpty || (vm.currentPlayer?.points ?? 0) <= 0) ? 0.55 : 1.0)
            .scaleEffect(animateSuccess ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: animateSuccess)
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
                        Text(secret)
                            .fixedSize(horizontal: false, vertical: true)
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

    private func refreshSelectionIfNeeded() {
        // si la sélection n'existe plus (ou est nil), on en choisit une par défaut
        if selectedPlayerID == nil || !vm.players.contains(where: { $0.id == selectedPlayerID }) {
            selectedPlayerID = vm.players.first(where: { $0.id != vm.currentPlayer?.id })?.id
        }
    }

    private func validateGuess() {
        guard let id = selectedPlayerID,
              let target = vm.players.first(where: { $0.id == id }),
              let me = vm.currentPlayer else { return }

        // 1) Si le secret a déjà été révélé -> message spécifique
        if target.secretRevealed {
            vm.message = "Ce secret a déjà été trouvé — plus de points à gagner."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        // 2) Vérifier qu'il y a bien un secret (non-nil/non-empty)
        guard let targetSecret = target.secret, !targetSecret.isEmpty else {
            vm.message = "Ce joueur n'a pas encore choisi son secret."
            return
        }

        // 3) Comparaison
        if selectedSecret == targetSecret {
            // ======= SUCCÈS =======
            vm.message = ""
            // son + haptics + confetti + animation du bouton
            AudioServicesPlaySystemSound(1025)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                animateSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation { animateSuccess = false }
            }

            confettiTrigger.toggle()
            showSuccess = true

            // 1) ajouter les points à celui qui trouve (+5)
            vm.changePointsForCurrentPlayer(by: 5) { ok, err in
                if !ok { vm.message = "Erreur en sauvegarde des points." }
            }

            // 2) marquer le secret du target comme trouvé côté serveur et décrémenter ses points
            let revealerId = me.id
            let pointsToRemove = target.points

            // on marque revealed (sans supprimer le secret) puis on remet les points du target à 0 (atomiquement)
            FirebaseService.shared.markSecretRevealed(playerId: target.id,
                                                      revealedBy: revealerId,
                                                      removeSecret: false) { err in
                DispatchQueue.main.async {
                    if let err = err {
                        print("Erreur markSecretRevealed:", err.localizedDescription)
                    } else {
                        // décrémente les points du target (atomique)
                        let delta = -Int64(pointsToRemove)
                        FirebaseService.shared.changePlayerPoints(uid: target.id, delta: delta) { err2 in
                            DispatchQueue.main.async {
                                if let err2 = err2 {
                                    print("Erreur changePlayerPoints pour target:", err2.localizedDescription)
                                } else {
                                    // update local model pour UX immédiate (listener fera la sync correcte)
                                    if var t = self.vm.players.first(where: { $0.id == target.id }) {
                                        t.secretRevealed = true
                                        t.points = max(0, t.points - pointsToRemove) // deviens 0
                                        if let idx = self.vm.players.firstIndex(where: { $0.id == t.id }) {
                                            self.vm.players[idx] = t
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        } else {
            // ======= ÉCHEC =======
            vm.message = "Mauvais secret ! -5 points"
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 5).repeatCount(3, autoreverses: false)) {
                shakeButton += 1
            }
            vm.changePointsForCurrentPlayer(by: -5) { ok, err in
                if !ok { print("Erreur décrément:", err ?? "") }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        // reset choix si tu veux
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
        Picker(selection: Binding(
            get: { selectedId ?? "" },
            set: { new in selectedId = new.isEmpty ? nil : new }
        ), label: label) {
            if list.isEmpty {
                Text("Aucun joueur").tag("")
            } else {
                ForEach(list, id: \.id) { p in
                    Text(p.username).tag(p.id)
                }
            }
        }
        .pickerStyle(MenuPickerStyle())
        // style du conteneur blanc
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
        )
        .padding(.horizontal)
    }

    private var label: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(players.first(where: { $0.id == selectedId })?.username ?? "Choisir un joueur")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedId == nil ? Color.gray : Color.primary)
                Text(list.isEmpty ? "Aucun joueur disponible" : (selectedId == nil ? "Sélectionnez une cible" : ""))
                    .font(.caption2)
                    .foregroundColor(Color.gray.opacity(0.8))
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .foregroundColor(Color.primary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }
}
