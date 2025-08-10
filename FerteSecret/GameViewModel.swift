//
//  GameViewModel.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//


//  GameViewModel.swift
import Foundation

class GameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var currentPlayer: Player?
    @Published var isLoggedIn = false
    @Published var codeInput: String = ""
    @Published var message: String = ""

    // Liste initiale de secrets
    @Published var availableSecrets = [
        "Dragon Slayer",
        "Master Chef",
        "Secret Agent",
        "Time Traveler",
        "Explorer",
        "Wizard",
        "Ninja",
        "Pirate",
        "Astronaut",
        "Detective"
    ]

    init() {
        // Création de 10 joueurs par défaut
        self.players = (1...10).map { i in
            Player(id: UUID(),
                   username: "Joueur \(i)",
                   secret: nil,
                   points: 5)
        }
    }

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
        // Retirer ce secret de la liste globale pour éviter les doublons
        availableSecrets.removeAll { $0 == secret }
    }

    func updatePlayer(_ player: Player) {
        if let idx = players.firstIndex(where: { $0.id == player.id }) {
            players[idx] = player
            currentPlayer = player
        }
    }
}
