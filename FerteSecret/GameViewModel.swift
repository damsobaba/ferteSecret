//
//  GameViewModel.swift
//

import Foundation
import Combine
import FirebaseAuth

// MARK: - Models
struct Player: Identifiable, Codable, Equatable {
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
    static let defaultSecrets: [String] = [
        "Déchiré mon pantalon en public.",
        "Couché sur une plage.",
        "Pris le téléphone d’un ami pour répondre à un message à sa place.",
        "Joué à cache-cache à l’âge adulte.",
        "Cassé quelque chose chez quelqu’un et rien dit.",
        "Couché dans une remorque.",
        "Joué avec des menottes (consenti).",
        "Embrassé un inconnu dans la rue.",
        "Fait une sextape (jamais publiée).",
        "Envoyé un message vocal de 5 minutes incompréhensible.",
        "Été pris·e à chanter très fort avec des écouteurs.",
        "Fait semblant d’être malade pour éviter le travail.",
        "Confondu deux jumeaux.",
        "Embrassé deux amis du même groupe.",
        "Stalké un ex et me suis fait griller.",
        "Embrassé le/la partenaire d’un ami.",
        "Dormi dans une cabine d’ascenseur bloquée.",
        "Menti pour coucher avec quelqu’un.",
        "Envoyé une photo hot par erreur.",
        "Dormi dans un ferry.",
        "Embrassé un·e collègue.",
        "Trébuché en entrant sur une scène.",
        "Fait un strip-tease devant du monde.",
        "Dormi dans un aéroport.",
        "Dormi dans une salle de cinéma vide.",
        "Essayé le naturisme en plein jour.",
        "Fini une soirée en sous-vêtements.",
        "Embrassé quelqu’un dans un taxi.",
        "Fait du naturisme sur une plage.",
        "Embrassé mon/ma voisin·e sur le palier.",
        "Confondu brosse à dents avec quelqu’un d’autre.",
        "Embrassé mon/ma voisin·e.",
        "Couché dans un garage.",
        "Couché avec quelqu’un sans connaître son prénom.",
        "Envoyé une photo floue en pensant que c’était stylé.",
        "Dormi dans un TER.",
        "Couché dans des toilettes de bar.",
        "Dormi dans une arrière-salle de bar.",
        "Ghosté quelqu’un sans explication.",
        "Dormi nu chez un·e ami·e.",
        "Vomi dans un sac à main.",
        "Envoyé un vocal honteux en public par erreur.",
        "Envoyé une story d’after envoyée au boulot.",
        "Couché avec un ex par ennui.",
        "Embrassé quelqu’un en couple (sans le savoir).",
        "Couché sur une machine à laver.",
        "Dormi dans une plage en hiver.",
        "Couché sur un toit.",
        "Couché dans une cave.",
        "Couché avec un·e collègue.",
        "Dormi dans un hall d’immeuble.",
        "Envoyé un message bourré à mon ex.",
        "Dormi dans une gare.",
        "Envoyé un meme très gênant au mauvais groupe.",
        "Applaudi au mauvais moment dans un spectacle.",
        "Crié juste pour l’écho dans une montagne.",
        "Vomi sur quelqu’un en soirée.",
        "Couché dans un grenier.",
        "Dormi dans un parc la nuit.",
        "Menti en disant “je t’aime”.",
        "Embrassé quelqu’un déguisé.",
        "Envoyé un message très gênant à la mauvaise personne.",
        "Embrassé trois personnes la même nuit.",
        "Oublié où j’avais garé ma voiture.",
        "Dormi dans une forêt.",
        "Caché une marque de suçon.",
        "Envoyé un répondeur honteux à 3h du matin.",
        "Embrassé deux personnes en moins d’une heure.",
        "Embrassé une personne rencontrée sur une app le jour même.",
        "Couché dans un parc la nuit.",
        "Dormi dans un métro à l’arrêt.",
        "Embrassé mon/ma boss.",
        "Marché avec du papier toilette collé à la chaussure.",
        "Embrassé quelqu’un pendant un défi.",
        "Dansé sur un bar.",
        "Envoyé un appel en visio sans le savoir.",
        "Dormi dans une plage de galets.",
        "Embrassé quelqu’un sous la pluie.",
        "Couché sur un trampoline.",
        "Embrassé un inconnu pendant un feu d’artifice.",
        "Couché dans une cabane.",
        "Pris un bain à minuit dans une piscine interdite.",
        "Dormi dans une colline.",
        "Embrassé un/une serveur·se.",
        "Couché dans un vestiaire.",
        "Embrassé un/une DJ.",
        "Fait tomber mon téléphone dans les toilettes.",
        "Couché dans une tente.",
        "Fait semblant d’avoir une panne pour draguer.",
        "Fait une soirée entière en pyjama.",
        "Piqué une crise de jalousie ridicule.",
        "Eu un crush sur un·e prof.",
        "Embrassé quelqu’un du même sexe.",
        "Appelé mon/ma partenaire par le prénom d’un ex.",
        "Dormi dans une cabine de plage.",
        "Essayé le rôle-play.",
        "Couché dans une voiture.",
        "Léché le sol d’une boîte de nuit (pari).",
        "Pris une douche à plusieurs.",
        "Dormi dans un terrain de jeu.",
        "Dormi dans un parking.",
        "Embrassé mon/ma prof.",
        "Dragué avec un faux prénom.",
        "Envoyé un snap compromettant à la mauvaise story.",
        "Envoyé un message où je critiquais quelqu’un… à la personne en question.",
        "Dormi dans une salle d’attente.",
        "Chanté ivre devant tout un bar.",
        "Dormi dans un hamac public.",
        "Dormi dans un bus de nuit.",
        "Couché dans un jacuzzi.",
        "Envoyé une capture d’écran d’une conversation… à la personne concernée.",
        "Couché dans une douche.",
        "Couché dans une cuisine.",
        "Envoyé un message copié-collé à deux personnes différentes.",
        "Envoyé un nude volontairement.",
        "Porté des chaussettes dépareillées à un rencard.",
        "Dormi dans une bibliothèque.",
        "Couché dans un cinéma vide.",
        "Envoyé des cœurs à la mauvaise personne.",
        "Embrassé quelqu’un pendant un mariage.",
        "Dormi dans un cimetière.",
        "Couché sur une table.",
        "Embrassé quelqu’un sur une piste de danse.",
        "Renvoyé un mail en « répondre à tous » par erreur.",
        "Fait tomber un verre au restaurant et accusé le vent.",
        "Parlé de quelqu’un alors qu’il/elle était derrière moi.",
        "Couché le premier soir.",
        "Couché dans une loge.",
        "Inventé un faux accent toute une soirée.",
        "Snobé quelqu’un que je n’avais pas reconnu.",
        "Fait l’amour sur une machine à laver en marche.",
        "Couché dehors sous la pluie.",
        "Ri tellement fort que je me suis étouffé.",
        "Couché dans une cabine d’essayage.",
        "Dormi dans un banc public.",
        "Dormi dans un toit.",
        "Couché dans un local à vélos.",
        "Couché dans un escalier.",
        "Couché sur un balcon."
    ]

    init() {
      
        // lors de l'init ou fetch
        FirebaseService.shared.fetchSecrets { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let remote):
                    // garde les defaults en tête, puis ajoute uniquement les extras distants
                    let extras = remote.filter { !GameViewModel.defaultSecrets.contains($0) }
                    self.availableSecrets = GameViewModel.defaultSecrets + extras
                case .failure(_):
                    // fallback : la liste locale par défaut
                    self.availableSecrets = GameViewModel.defaultSecrets
                }
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
        FirebaseService.shared.fetchPlayersOnce { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let arr):
                    print("fetchPlayersOnce -> \(arr.count) docs")
                case .failure(let err):
                    print("fetchPlayersOnce error ->", err.localizedDescription)
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
    /// Ajoute `amount` points au joueur identifié par `playerId` puis persiste
    // GameViewModel.swift
    func addPoints(to playerId: String, amount: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let idx = self.players.firstIndex(where: { $0.id == playerId }) else { return }

            var p = self.players[idx]
            p.points += amount
            if p.points < 0 { p.points = 0 }

            // Update local model immediately
            self.players[idx] = p
            if self.currentPlayer?.id == p.id {
                self.currentPlayer = p
            }

            // Persist to Firestore and log success/error
            FirebaseService.shared.upsertPlayer(uid: p.id, username: p.username, secret: p.secret, points: p.points) { err in
                DispatchQueue.main.async {
                    if let err = err {
                        print("DEBUG: Failed to persist points for \(p.username): \(err.localizedDescription)")
                        // informe l'utilisateur dans l'UI
                        self.message = "Erreur en sauvegarde (vérifie règles Firestore)."
                    } else {
                        print("DEBUG: Successfully persisted points for \(p.username) -> \(p.points)")
                        // optional: clear message or show success
                        self.message = "Points appliqués à \(p.username) : \(p.points)."
                    }
                }
            }
        }
    }
}
