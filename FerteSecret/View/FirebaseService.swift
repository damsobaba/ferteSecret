//
//  FirebaseService.swift
//

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
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snap, err in
                if let err = err { onUpdate(.failure(err)); return }
                let arr = snap?.documents.map { ($0.documentID, $0.data()) } ?? []
                onUpdate(.success(arr))
            }
    }

    func stopListeningPlayers() {
        playersListener?.remove()
        playersListener = nil
    }

    // MARK: - Secrets

    /// Fetch secrets from secrets/all.list
    func fetchSecrets(completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection("secrets").document("all").getDocument { doc, err in
            if let err = err { completion(.failure(err)); return }
            let list = doc?.data()?["list"] as? [String] ?? []
            completion(.success(list))
        }
    }

    // MARK: - Upsert Player

    /// Upsert players/{uid or docId}
    // FirebaseService.swift
    func upsertPlayer(uid: String, username: String, secret: String?, points: Int?, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("players").document(uid)
        var data: [String: Any] = [
            "username": username,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let secret = secret { data["secret"] = secret }
        if let points = points { data["points"] = points }

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

    // Optional helper
    func fetchPlayerByUsername(_ username: String, completion: @escaping (Result<(id: String, data: [String:Any])?, Error>) -> Void) {
        db.collection("players").whereField("username", isEqualTo: username).getDocuments { snap, err in
            if let err = err { completion(.failure(err)); return }
            if let doc = snap?.documents.first { completion(.success((doc.documentID, doc.data()))); return }
            completion(.success(nil))
        }
    }
    // MARK: - Helpers pour secret & points

    /// Définit / met à jour le secret pour players/{uid}
    func setPlayerSecret(uid: String, secret: String, completion: ((Error?) -> Void)? = nil) {
        let ref = db.collection("players").document(uid)
        ref.setData([
            "secret": secret,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { err in
            if let err = err {
                print("setPlayerSecret error:", err.localizedDescription)
            } else {
                print("setPlayerSecret success for", uid)
            }
            completion?(err)
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
}
