//
//  ProfileView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 08/08/2025.
//

//  ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: GameViewModel
    @State private var showSecret = false

    var body: some View {
        ScrollView{
            ZStack {
                GradientBackground()
                VStack(spacing: 30) {
                    // Avatar + pseudo
                    Image(systemName: "person.crop.circle.fill")
                        .resizable().frame(width: 100, height: 100)
                        .background(Color.white.opacity(0.2)).clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                    Text(vm.currentPlayer?.username ?? "—")
                        .font(.title2).foregroundColor(.white)

                    // Secret card
                    VStack(spacing: 12) {
                        Text("Votre Secret").font(.headline).foregroundColor(.white)
                        Text(showSecret ? (vm.currentPlayer?.secret ?? "—") : "••••••")
                            .font(.title3).foregroundColor(.white)
                    }
                    .padding().background(Color.white.opacity(0.15))
                    .cornerRadius(12).overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )

                    // Boutons
                    VStack(spacing: 16) {
                        Button(showSecret ? "Masquer secret" : "Voir secret") {
                            showSecret.toggle()
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.white.opacity(0.25)).foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Déconnexion") {
                            vm.isLoggedIn = false
                            vm.currentPlayer = nil
                            vm.availableSecrets = ["Dragon Slayer","Master Chef","Secret Agent","Time Traveler"]
                            vm.message = ""
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.8)).foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
