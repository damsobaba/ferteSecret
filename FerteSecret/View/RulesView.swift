//
//  RulesView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//


//  RulesView.swift
import SwiftUI

struct RulesView: View {
    var body: some View {
        ZStack {
            GradientBackground()
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
                }
                .padding()
            }
        }
    }
}
