//
//  GameViewModel.swift
//

import Foundation
import Combine
import FirebaseAuth

// MARK: - Models
struct Player: Identifiable, Codable {
    let id: String
    let username: String
    var secret: String?
    var points: Int
}

// ViewModel
final class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPlayer: Player?
    @Published var isLoggedIn: Bool = false
    @Published var availableSecrets: [String] = []
    @Published var message: String = ""
    @Published var codeInput: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        // load secrets once
        FirebaseService.shared.fetchSecrets { [weak self] res in
            DispatchQueue.main.async {
                if case let .success(list) = res { self?.availableSecrets = list }
            }
        }

        // start players listener
        startPlayersListener()

        // optional: ensure anon auth if Firestore rules need it for reads
        if Auth.auth().currentUser == nil {
            FirebaseService.shared.signInAnonymously { result in
                switch result {
                case .success(let u):
                    print("anon signed in: \(u.uid)")
                case .failure(let err):
                    print("anon sign-in failed:", err.localizedDescription)
                }
            }
        }
    }

    private func startPlayersListener() {
        FirebaseService.shared.listenPlayers { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(let arr):
                    self?.players = arr.map { (id, data) in
                        let username = data["username"] as? String ?? "—"
                        let secret = data["secret"] as? String
                        let points = data["points"] as? Int ?? 5
                        return Player(id: id, username: username, secret: secret, points: points)
                    }
                case .failure(let err):
                    print("players listener error:", err.localizedDescription)
                }
            }
        }
    }

    deinit {
        FirebaseService.shared.stopListeningPlayers()
    }

    // MARK: - Auth

    func register(email: String, password: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FirebaseService.shared.createUser(email: email, password: password) { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(let user):
                    let uid = user.uid
                    // create player doc
                    FirebaseService.shared.upsertPlayer(uid: uid, username: username, secret: nil, points: 5)
                    let newP = Player(id: uid, username: username, secret: nil, points: 5)
                    self?.currentPlayer = newP
                    self?.isLoggedIn = true
                    // local append to show immediate UI (listener will sync)
                    if !(self?.players.contains(where: { $0.id == uid }) ?? false) {
                        self?.players.append(newP)
                    }
                    completion(.success(()))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FirebaseService.shared.signIn(email: email, password: password) { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success(let user):
                    let uid = user.uid
                    // try set current from local players (listener will update soon)
                    if let existing = self?.players.first(where: { $0.id == uid }) {
                        self?.currentPlayer = existing
                    } else {
                        let username = user.displayName ?? user.email?.split(separator: "@").first.map(String.init) ?? "Joueur_\(uid.prefix(6))"
                        self?.currentPlayer = Player(id: uid, username: username, secret: nil, points: 5)
                    }
                    self?.isLoggedIn = true
                    // ensure doc exists
                    FirebaseService.shared.upsertPlayer(uid: uid, username: self?.currentPlayer?.username ?? "Player", secret: self?.currentPlayer?.secret, points: self?.currentPlayer?.points)
                    completion(.success(()))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }

    /// create a local player (no Auth). Useful for quick start
    func createLocalPlayer(username: String, secret: String?) {
        let docId = UUID().uuidString
        let newP = Player(id: docId, username: username, secret: secret, points: 5)
        DispatchQueue.main.async {
            self.players.append(newP)
            self.currentPlayer = newP
            self.isLoggedIn = true
        }
        FirebaseService.shared.upsertPlayer(uid: docId, username: username, secret: secret, points: 5)
    }

    // MARK: - Secrets & points

    func chooseSecret(_ secret: String) {
        DispatchQueue.main.async {
            guard var p = self.currentPlayer else { return }
            p.secret = secret
            self.currentPlayer = p

            FirebaseService.shared.upsertPlayer(uid: p.id, username: p.username, secret: secret, points: p.points) { err in
                DispatchQueue.main.async {
                    if let err = err {
                        self.message = "Erreur sauvegarde : \(err.localizedDescription)"
                        print("chooseSecret -> upsert error:", err.localizedDescription)
                    } else {
                        self.message = "Secret sauvegardé !"
                        print("chooseSecret -> success for player:", p.id, p.username)
                    }
                }
            }
        }
    }

    // appelle setPlayerSecret, en s'assurant que l'utilisateur est authentifié (ou s'auth anonymement)
    func chooseSecretForCurrentUser(secret: String, completion: ((Bool,String?)->Void)? = nil) {
        // ensure we have an uid (auth or anon)
        if Auth.auth().currentUser == nil {
            // sign-in anonymously then write
            FirebaseService.shared.signInAnonymously { res in
                switch res {
                case .success(let user):
                    self._writeSecret(uid: user.uid, secret: secret, completion: completion)
                case .failure(let err):
                    completion?(false, "Auth failed: \(err.localizedDescription)")
                }
            }
        } else {
            guard let uid = Auth.auth().currentUser?.uid else {
                completion?(false, "No uid")
                return
            }
            _writeSecret(uid: uid, secret: secret, completion: completion)
        }
    }

    private func _writeSecret(uid: String, secret: String, completion: ((Bool,String?)->Void)?) {
        // update local model immediately
        if var p = self.currentPlayer {
            p.secret = secret
            self.currentPlayer = p
            if let idx = self.players.firstIndex(where: { $0.id == p.id }) { self.players[idx] = p }
        } else {
            // set currentPlayer if not set (use uid)
            let username = Auth.auth().currentUser?.displayName ?? Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "Joueur_\(uid.prefix(6))"
            let newP = Player(id: uid, username: username, secret: secret, points: 5)
            self.currentPlayer = newP
            self.players.append(newP)
        }

        FirebaseService.shared.setPlayerSecret(uid: uid, secret: secret) { err in
            DispatchQueue.main.async {
                if let err = err {
                    completion?(false, err.localizedDescription)
                } else {
                    completion?(true, nil)
                }
            }
        }
    }

    // Incrémente les points du joueur courant (utiliser +3 ou -1 etc)
    func changePointsForCurrentPlayer(by delta: Int64, completion: ((Bool,String?)->Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid ?? currentPlayer?.id else {
            completion?(false, "No player id")
            return
        }

        FirebaseService.shared.changePlayerPoints(uid: uid, delta: delta) { err in
            DispatchQueue.main.async {
                if let err = err {
                    completion?(false, err.localizedDescription)
                } else {
                    // mettre à jour localement aussi (optionnel: lire depuis firestore listener)
                    if var p = self.currentPlayer {
                        p.points = max(0, p.points + Int(delta))
                        self.currentPlayer = p
                        if let idx = self.players.firstIndex(where: { $0.id == p.id }) { self.players[idx] = p }
                    }
                    completion?(true, nil)
                }
            }
        }
    }

    func updatePlayer(_ player: Player) {
        if let i = players.firstIndex(where: { $0.id == player.id }) { players[i] = player }
        if currentPlayer?.id == player.id { currentPlayer = player }
        FirebaseService.shared.upsertPlayer(uid: player.id, username: player.username, secret: player.secret, points: player.points)
    }

    // quick guess check (used by CodeEntryView)
    func attemptGuess(targetId: String, guessSecret: String) -> Bool {
        guard let target = players.first(where: { $0.id == targetId }), var me = currentPlayer else { return false }
        guard let tSecret = target.secret else {
            message = "Ce joueur n'a pas choisi de secret."
            return false
        }
        if guessSecret == tSecret {
            me.points += 3
            updatePlayer(me)
            message = "Bravo ! +3 points"
            return true
        } else {
            me.points = max(0, me.points - 1)
            updatePlayer(me)
            message = "Mauvais secret ! -1 point"
            return false
        }
    }

    func setCurrentPlayer(byDocId docId: String) {
        if let p = players.first(where: { $0.id == docId }) {
            currentPlayer = p
            isLoggedIn = true
        } else {
            print("player not found for id", docId)
        }
    }
}
