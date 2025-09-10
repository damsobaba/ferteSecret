// RulesView.swift
import SwiftUI

struct RulesView: View {
    @ObservedObject var vm: GameViewModel

    @State private var showLeaderboard = false
    @State private var selectedPlayer: Player? = nil
    @State private var animateUpdate = false

    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("🔐 Objectif").font(.headline)
                        Text("Trouver le code secret des autres joueurs en IRL pour marquer des points.")
                    }
                    .foregroundColor(.white)

                    Group {
                        Text("⚙️ Comment jouer").font(.headline)
                        Text("""
1. Chaque joueur choisit un secret.
2. Vous disposez de 5 points au départ.
3. À chaque mauvaise tentative, vous perdez 1 point et le bouton shake.
4. À chaque bonne réponse, vous gagnez 3 points, confettis et son !
""")
                    }
                    .foregroundColor(.white)

                    Group {
                        Text("📱 Interface").font(.headline)
                        Text("– Accueil : deviner un secret\n– Règles : ce résumé\n– Profil : vos infos et déconnexion")
                    }
                    .foregroundColor(.white)

                    // Spacer then button to show leaderboard
                    Spacer().frame(height: 18)
                    Button(action: {
                        withAnimation(.spring()) { showLeaderboard = true }
                    }) {
                        HStack(alignment: .center, spacing: 16) {
                            // icône ronde dégradée
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#E286CA"), Color(hex: "#BD3993")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 48, height: 48)
                                    .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

                                Image(systemName: "list.number")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }

                            // texte principal + sous-texte
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Voir le classement")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .kerning(0.2)

                                Text("Tous les joueurs et leurs points — mis à jour en temps réel")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.88))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.025))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 6)
                    Spacer(minLength: 200)

                }
                .padding()
            }
        }
        // Leaderboard sheet
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
        // Detail sheet when tapping a player row (optional)
        .sheet(item: $selectedPlayer) { player in
            PlayerDetailView(player: player, vm: vm)
        }
    }
}


// MARK: - LeaderboardView (sheet content)
private struct LeaderboardView: View {
    @ObservedObject var vm: GameViewModel
    @Binding var selectedPlayer: Player?

    // computed sorted players (desc by points, newest first as tie-breaker)
    private var ranked: [Player] {
        vm.players.sorted {
            if $0.points == $1.points { return $0.username < $1.username }
            return $0.points > $1.points
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // header
            HStack {
                VStack(alignment: .leading) {
                    Text("Classement")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Mis à jour en temps réel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            // table header
            HStack {
                Text("#").frame(width: 30, alignment: .leading).foregroundColor(.secondary)
                Text("Joueur").fontWeight(.semibold)
                Spacer()
                Text("Points").fontWeight(.semibold)
            }
            .padding(.horizontal)

            Divider()

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { idx, player in
                        // each row is a button — tapping shows detail sheet
                        Button {
                            selectedPlayer = player
                        } label: {
                            HStack(spacing: 12) {
                                // Rank circle
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color(hex: "#E286CA").opacity(0.95), Color(hex: "#BD3993").opacity(0.95)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .shadow(radius: 4)
                                    Text("\(idx + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(player.username)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    // small meta (optional)
                                    // Text(player.id).font(.caption).foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(player.points)")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.01))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical)
            }
        }
        .padding(.top)
    }
}


// MARK: - PlayerDetailView (sheet shown when tapping a row)
private struct PlayerDetailView: View {
    let player: Player
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text(player.username).font(.title2).fontWeight(.bold)
                    Text("ID: \(player.id)").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text("\(player.points) pts")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding()

            Divider()

            // IMPORTANT: ne pas afficher le secret publiquement — ici on masque par défaut.
            // Si tu veux autoriser l'admin à voir, tu peux ajouter une vérif.
            VStack(alignment: .leading, spacing: 8) {
                Text("Secret")
                    .font(.headline)
                Text("********") // cacher le secret pour la confidentialité
                    .foregroundColor(.secondary)
                Text("Si tu veux voir le secret, il faut être admin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}


// MARK: - Color hex helper (si tu l'as déjà, ignore)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
