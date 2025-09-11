// FirebaseService.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    private var playersListener: ListenerRegistration?

    private init() {}

    // MARK: - Auth

    func signIn(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { res, err in
            if let err = err { completion(.failure(err)); return }
            if let user = res?.user { completion(.success(user)); return }
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned"])))
        }
    }

    func createUser(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { res, err in
            if let err = err { completion(.failure(err)); return }
            if let user = res?.user { completion(.success(user)); return }
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned"])))
        }
    }

    func signInAnonymously(completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().signInAnonymously { res, err in
            if let err = err { completion(.failure(err)); return }
            if let u = res?.user { completion(.success(u)); return }
            completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Players listener

    /// Listen players collection in realtime and return array of (docId, data)
    func listenPlayers(onUpdate: @escaping (Result<[(id: String, data: [String:Any])], Error>) -> Void) {
        playersListener?.remove()
        playersListener = db.collection("players")
            .addSnapshotListener { snap, err in
                if let err = err {
                    print("[FirebaseService] listenPlayers error:", err.localizedDescription)
                    onUpdate(.failure(err))
                    return
                }
                guard let docs = snap?.documents else {
                    print("[FirebaseService] listenPlayers: no documents")
                    onUpdate(.success([]))
                    return
                }
                let arr = docs.map { ($0.documentID, $0.data()) }
                print("[FirebaseService] listenPlayers: got \(arr.count) players (docs)")
                onUpdate(.success(arr))
            }
    }

    func stopListeningPlayers() {
        playersListener?.remove()
        playersListener = nil
    }

    // MARK: - Secrets

    /// Fetch secrets from secrets/all document (field "list")
    func fetchSecrets(completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection("secrets").document("all").getDocument { doc, err in
            if let err = err { completion(.failure(err)); return }
            let list = doc?.data()?["list"] as? [String] ?? []
            completion(.success(list))
        }
    }

    // MARK: - Upsert Player

    /// Upsert players/{uid or docId}
    func upsertPlayer(uid: String, username: String, secret: String?, points: Int?, secretRevealed: Bool? = nil, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("players").document(uid)
        var data: [String: Any] = [
            "username": username,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let secret = secret { data["secret"] = secret }
        if let points = points { data["points"] = points }
        if let revealed = secretRevealed { data["secretRevealed"] = revealed }

        ref.setData(data, merge: true) { err in
            if let err = err {
                print("upsertPlayer setData error:", err.localizedDescription)
                completion?(err)
                return
            }
            // ensure createdAt exists (best-effort)
            ref.getDocument { snap, _ in
                if let snap = snap, snap.exists, snap.data()?["createdAt"] == nil {
                    ref.setData(["createdAt": FieldValue.serverTimestamp()], merge: true)
                }
                print("upsertPlayer success for uid:", uid)
                completion?(nil)
            }
        }
    }

    func fetchPlayerByUsername(_ username: String, completion: @escaping (Result<(id: String, data: [String:Any])?, Error>) -> Void) {
        db.collection("players").whereField("username", isEqualTo: username).getDocuments { snap, err in
            if let err = err { completion(.failure(err)); return }
            if let doc = snap?.documents.first { completion(.success((doc.documentID, doc.data()))); return }
            completion(.success(nil))
        }
    }

    // MARK: - Helpers pour secret & points

    /// Définit / met à jour le secret pour players/{uid} (par défaut secretRevealed = false)
    func setPlayerSecret(uid: String, secret: String, revealed: Bool = false, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("players").document(uid)
        let data: [String: Any] = [
            "secret": secret,
            "secretRevealed": revealed,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        ref.setData(data, merge: true) { err in
            if let err = err {
                print("setPlayerSecret error:", err.localizedDescription)
                completion?(err)
            } else {
                print("setPlayerSecret success for", uid)
                completion?(nil)
            }
        }
    }

    /// Incrémente (ou décrémente si delta négatif) le champ points atomiquement
    func changePlayerPoints(uid: String, delta: Int64, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("players").document(uid)
        ref.updateData([
            "points": FieldValue.increment(delta),
            "updatedAt": FieldValue.serverTimestamp()
        ]) { err in
            if let err = err {
                print("changePlayerPoints error:", err.localizedDescription)
            } else {
                print("changePlayerPoints success for", uid, "delta:", delta)
            }
            completion?(err)
        }
    }

    func fetchPlayersOnce(completion: @escaping (Result<[(id:String, data:[String:Any])], Error>) -> Void) {
        db.collection("players").getDocuments { snap, err in
            if let err = err { completion(.failure(err)); return }
            let arr = snap?.documents.map { ($0.documentID, $0.data()) } ?? []
            completion(.success(arr))
        }
    }

    // FirebaseService.swift

    /// marque le secret comme trouvé ; optionnellement décrémente les points (atomique)
    func markSecretRevealed(playerId: String,
                            revealedBy: String?,
                            removeSecret: Bool = false,
                            deductPoints: Int? = nil,
                            completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("players").document(playerId)

        var data: [String: Any] = [
            "secretRevealed": true,
            "revealedAt": FieldValue.serverTimestamp()
        ]
        if let by = revealedBy {
            data["revealedBy"] = by
        }

        // Si l'appel demande explicitement de supprimer le secret, on peut le faire,
        // mais par défaut on ne supprime pas (pour conserver le secret en base).
        if removeSecret {
            data["secret"] = FieldValue.delete()
        }

        // Si on doit déduire des points, utilise FieldValue.increment(-deduct)
        if let toDeduct = deductPoints, toDeduct != 0 {
            data["points"] = FieldValue.increment(Int64(-toDeduct))
        }

        ref.setData(data, merge: true) { err in
            completion?(err)
        }
    }

    // Fetch single player doc (returns optional tuple)
    func fetchPlayer(uid: String, completion: @escaping (Result<(id: String, data: [String:Any])?, Error>) -> Void) {
        let ref = db.collection("players").document(uid)
        ref.getDocument { snap, err in
            if let err = err {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }

            guard let snap = snap, snap.exists else {
                DispatchQueue.main.async { completion(.success(nil)) }
                return
            }

            // snap.data() est optionnel -> on retourne un dictionnaire vide si nil
            let data = snap.data() ?? [:]
            DispatchQueue.main.async { completion(.success((snap.documentID, data))) }
        }
    }

    // MARK: - Transaction helper (atomique)
    /// Tentative atomique : si le secret du target n'a pas encore été révélé,
    /// on marque secretRevealed = true, (optionnellement supprime secret),
    /// et on incrémente les points du revealer.
    ///
    /// IMPORTANT: côté sécurité il vaut mieux faire ceci côté serveur (Cloud Function)
    /// pour éviter que des clients malicieux n'appellent la transaction avec des paramètres truqués.
    func revealSecretAndGrantPointsTransaction(targetPlayerId: String, revealerId: String, pointsToGrant: Int64, removeSecret: Bool = true, completion: @escaping (Error?) -> Void) {
        let targetRef = db.collection("players").document(targetPlayerId)
        let revealerRef = db.collection("players").document(revealerId)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // read target
            do {
                let targetSnap = try transaction.getDocument(targetRef)
                let revealed = targetSnap.data()?["secretRevealed"] as? Bool ?? false
                if revealed {
                    // already revealed
                    let e = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Secret already revealed"])
                    errorPointer?.pointee = e
                    return nil
                }

                // mark revealed and optional delete secret
                var update: [String: Any] = [
                    "secretRevealed": true,
                    "revealedAt": FieldValue.serverTimestamp(),
                    "revealedBy": revealerId
                ]
                if removeSecret {
                    update["secret"] = FieldValue.delete()
                }
                transaction.setData(update, forDocument: targetRef, merge: true)

                // increment revealer points
                transaction.updateData(["points": FieldValue.increment(pointsToGrant), "updatedAt": FieldValue.serverTimestamp()], forDocument: revealerRef)

            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }, completion: { _, err in
            if let err = err {
                print("revealSecretAndGrantPointsTransaction error:", err.localizedDescription)
            } else {
                print("revealSecretAndGrantPointsTransaction success: target=\(targetPlayerId) revealer=\(revealerId) +\(pointsToGrant)")
            }
            completion(err)
        })
    }
}
