import SwiftUI

struct SecretSelectionView: View {
    @ObservedObject var vm: GameViewModel
    @State private var showingConfirm: String? = nil
    @State private var showLoginHint: Bool = false

    // fallback local si vm.availableSecrets est vide
    private let defaultSecrets: [String] = [
        "Dragon Slayer", "Master Chef", "Secret Agent", "Time Traveler",
        "Explorer", "Wizard", "Ninja", "Pirate", "Astronaut", "Detective"
    ]

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Choisissez votre secret")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.top, 18)

                    // hint si pas connecté
                    if !vm.isLoggedIn {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Connectez-vous pour attribuer un secret (optionnel).")
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            Button("Se connecter") {
                                showLoginHint = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(displayedSecrets(), id: \.self) { secret in
                            secretRow(secret: secret)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.vertical, 8)
            }
        }
        // Confirmation alert sheet
        .alert(item: $showingConfirm) { secret in
            Alert(
                title: Text("Valider le secret"),
                message: Text("Voulez-vous choisir le secret « \(secret) » ?"),
                primaryButton: .default(Text("Oui"), action: {
                    vm.chooseSecret(secret)
                }),
                secondaryButton: .cancel()
            )
        }
        .alert("Se connecter", isPresented: $showLoginHint) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Va dans l'onglet Profil pour créer/te connecter à un compte.")
        }
        .onAppear {
            // si vm.availableSecrets est vide, on lui fournit la liste par défaut
            if vm.availableSecrets.isEmpty {
                vm.availableSecrets = defaultSecrets
            }
        }
    }

    // MARK: - Sous-vues

    @ViewBuilder
    private func secretRow(secret: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(secret)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(takenBy(secret: secret) ?? "Disponible")
                    .font(.caption)
                    .foregroundColor(takenBy(secret: secret) == nil ? Color.white.opacity(0.7) : Color.yellow.opacity(0.9))
            }

            Spacer()

            if takenBy(secret: secret) != nil {
                Text("Attribué")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            } else {
                Button(action: {
                    // si pas connecté -> on propose de se connecter
                    if !vm.isLoggedIn {
                        showLoginHint = true
                        return
                    }
                    showingConfirm = secret
                }) {
                    Text("Choisir")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!vm.isLoggedIn) // sécurité UX
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    // retourne la liste à afficher : vm.availableSecrets si disponible, sinon fallback
    private func displayedSecrets() -> [String] {
        return vm.availableSecrets.isEmpty ? defaultSecrets : vm.availableSecrets
    }

    // helper: returns username if secret already taken
    private func takenBy(secret: String) -> String? {
        if let p = vm.players.first(where: { $0.secret == secret }) {
            return p.username
        }
        return nil
    }
}

// Allow Alert to take a String as Identifiable (place this once in project)
extension String: Identifiable {
    public var id: String { self }
}
