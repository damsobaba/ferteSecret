//
//  ContentView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 08/08/2025.
//

//  FerteSecretApp.swift
import SwiftUI

@main
struct FerteSecretApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//  ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        Group {
            if !vm.isLoggedIn {
                LoginView(vm: vm)
            } else if vm.currentPlayer?.secret == nil {
                SecretSelectionView(vm: vm)
            } else {
                MainTabView(vm: vm)
            }
        }
    }
}

//  GameViewModel.swift
import Foundation

class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayer: Player?
    @Published var isLoggedIn = false
    @Published var codeInput: String = ""
    @Published var message: String = ""

    // Liste initiale de secrets
    @Published var availableSecrets = ["Dragon Slayer", "Master Chef", "Secret Agent", "Time Traveler"]

    func login(username: String) {
        if let existing = players.first(where: { $0.username == username }) {
            currentPlayer = existing
        } else {
            let newPlayer = Player(id: UUID(), username: username, secret: nil, points: 5)
            players.append(newPlayer)
            currentPlayer = newPlayer
        }
        isLoggedIn = true
    }

    func chooseSecret(_ secret: String) {
        guard var p = currentPlayer else { return }
        p.secret = secret
        updatePlayer(p)
        // Retirer ce secret de la liste globale (pour les pickers futurs)
        availableSecrets.removeAll { $0 == secret }
    }

    func submitCode() {
        // Cette méthode est remplacée par validateGuess() dans CodeEntryView
    }

    func updatePlayer(_ player: Player) {
        if let idx = players.firstIndex(where: { $0.id == player.id }) {
            players[idx] = player
            currentPlayer = player
        }
    }
}

//  Player.swift
import Foundation

struct Player: Identifiable, Codable {
    let id: UUID
    let username: String
    var secret: String?
    var points: Int
}

//  Extensions.swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64(); Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int>>8)*17, (int>>4&0xF)*17, (int&0xF)*17)
        case 6: (a, r, g, b) = (255, int>>16, int>>8&0xFF, int&0xFF)
        case 8: (a, r, g, b) = (int>>24, int>>16&0xFF, int>>8&0xFF, int&0xFF)
        default: (a, r, g, b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red: Double(r)/255,
                  green: Double(g)/255,
                  blue: Double(b)/255,
                  opacity: Double(a)/255)
    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#E286CA"),
                Color(hex: "#BD3993"),
                Color(hex: "#465FB0")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

//  LoginView.swift
import SwiftUI

struct LoginView: View {
    @ObservedObject var vm: GameViewModel
    @State private var username: String = ""

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 20) {
                Text("Secret Story")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                TextField("Identifiant", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Button("Se connecter") {
                    vm.login(username: username)
                }
                .disabled(username.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

//  SecretSelectionView.swift
import SwiftUI

struct SecretSelectionView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choisissez votre secret")
                        .font(.title2)
                        .foregroundColor(.white)
                    ForEach(vm.availableSecrets, id: \.self) { secret in
                        Button(secret) {
                            vm.chooseSecret(secret)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
}

//  MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        TabView {
            CodeEntryView(vm: vm)
                .tabItem { Label("Accueil", systemImage: "house") }
            RulesView()
                .tabItem { Label("Règles", systemImage: "book") }
            ProfileView(vm: vm)
                .tabItem { Label("Profil", systemImage: "person.circle") }
        }
    }
}

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

//  ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: GameViewModel
    @State private var showSecret = false

    var body: some View {
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
        .ignoresSafeArea(edges: .bottom)
    }
}

//  CodeEntryView.swift
import SwiftUI
import ConfettiSwiftUI
import AVFoundation

struct CodeEntryView: View {
    @ObservedObject var vm: GameViewModel

    @State private var shakeButton = 0
    @State private var showSuccess = false
    @State private var confettiTrigger = false

    @State private var selectedPlayerID: UUID?
    @State private var selectedSecret = ""

    var body: some View {
        ZStack {
            GradientBackground()
            VStack(spacing: 0) {
                Image("eye")
                    .resizable().scaledToFit()
                    .frame(width:150, height:150)
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20)
                    .padding(.bottom, 40)

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Trouve le secret")
                            .font(.system(size:28, weight:.bold, design:.rounded))
                            .foregroundColor(.white)
                        Text("Points: \(vm.currentPlayer?.points ?? 0)")
                            .foregroundColor(.white)

                        Picker("Joueur", selection: Binding(
                            get: { selectedPlayerID ?? vm.players.first?.id },
                            set: { selectedPlayerID = $0 }
                        )) {
                            ForEach(vm.players.filter { $0.id != vm.currentPlayer?.id }) { player in
                                Text(player.username).tag(player.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding().background(Color.white.opacity(0.2))
                        .cornerRadius(8).foregroundColor(.white)

                        Picker("Secret", selection: $selectedSecret) {
                            ForEach(vm.availableSecrets, id:\.self) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding().background(Color.white.opacity(0.2))
                        .cornerRadius(8).foregroundColor(.white)

                        Button {
                            validateGuess()
                        } label: {
                            Text("Valider")
                                .frame(maxWidth:.infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .modifier(ShakeEffect(shakes:CGFloat(shakeButton)))
                        .padding(.horizontal)

                        if !vm.message.isEmpty {
                            Text(vm.message)
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom,50)
                }
                .confettiCannon(trigger:$confettiTrigger, num:100, rainHeight:600, repetition:1)
            }
            .ignoresSafeArea(edges:.top)
        }
        .alert("Bravo !", isPresented:$showSuccess) {
            Button("OK", role:.cancel){}
        } message:{
            Text("Vous avez gagné 3 points ! 🎉")
        }
        .onAppear {
            selectedPlayerID = vm.players.first(where:{ $0.id != vm.currentPlayer?.id })?.id
            selectedSecret   = vm.availableSecrets.first ?? ""
        }
    }

    private func validateGuess() {
        guard let id = selectedPlayerID,
              let target = vm.players.first(where:{ $0.id == id }),
              let me     = vm.currentPlayer
        else { return }

        if selectedSecret == target.secret {
            vm.message = ""
            var p = me; p.points += 3; vm.updatePlayer(p)
            AudioServicesPlaySystemSound(1025)
            confettiTrigger.toggle()
            showSuccess = true
        } else {
            var p = me; p.points = max(0, p.points-1); vm.updatePlayer(p)
            vm.message = "Mauvais secret !"
            withAnimation(.interpolatingSpring(stiffness:200, damping:5)
                          .repeatCount(3, autoreverses:false)) {
                shakeButton += 1
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        // Réinitialiser le picker secret
        selectedSecret = vm.availableSecrets.first ?? ""
    }
}
