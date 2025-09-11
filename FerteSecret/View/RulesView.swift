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
Les règles du jeu sont les suivantes dans Secret Ferté chacun des habitants échangent son secret à la voix contre 10 points 

🎯Tous les habitants doivent tenter de dissimuler leur secret pendant l'aventure tout en enquêtant pour découvrir les secrets des autres habitants.

📳Lorsqu'un habitant pense avoir découvert un secret : ils BUZZENT!
S'ils pensent avoir découvert le bon secret, il remporte la totalité des points du candidat dont a été découvert le secret. S'il se trompe, la voix lui retire 5 points de sa cagnotte.
LE BUZZ coûte 5 points ! Il ne faut donc pas trop buzzer !!!

✨La Voix a cependant tout prévu !
À tout moment les candidats peuvent renflouer leur cagnotte de points grâce à des missions secrètes ou à des jeux ponctuelles

⚠️Attention dans Secret Ferté, il est interdit de parler ou de faire allusion à son secret sous peine de sanction !

Que la chasse aux secrets commencent c'est tout pour le moment
""")
                    }
                    .foregroundColor(.white)

                    Group {
                        Text("📱 Interface").font(.headline)
                        Text("– Accueil : deviner un secret\n– Règles : ce résumé\n– Profil : vos infos et déconnexion")
                    }
                    .foregroundColor(.white)


                }
                .padding()
            }
        }

    }
}


// MARK: - LeaderboardView (sheet content)
 struct LeaderboardView: View {
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
