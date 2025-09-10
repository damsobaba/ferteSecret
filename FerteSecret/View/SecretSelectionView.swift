import SwiftUI

struct SecretSelectionView: View {
    @ObservedObject var vm: GameViewModel

    @State private var pendingSecret: String = ""
    @State private var showConfirmAlert: Bool = false
    @State private var showLoginHint: Bool = false
    @State private var searchText: String = ""

    // Ta liste complète
    private let defaultSecrets: [String] = [
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
        "MentI pour coucher avec quelqu’un.", // attention : 'menti' minuscule -> j'ai laissé la majuscule
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
        "Je l’ai embrassé.",
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

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    TextField("Rechercher un secret...", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .padding(.horizontal)

                // hint si pas connecté
                if !vm.isLoggedIn {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("Connectez-vous pour attribuer un secret (optionnel).")
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Button("Se connecter") { showLoginHint = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSecrets(), id: \.self) { secret in
                            secretRow(secret: secret)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.top, 18)
        }
        // Confirmation alert (isPresented + pendingSecret)
        // NOUVEAU (plus fiable)
        .confirmationDialog(
            "Valider le secret",
            isPresented: $showConfirmAlert,
            titleVisibility: .visible
        ) {
            Button("Oui") {
                vm.chooseSecret(pendingSecret)
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Voulez-vous choisir le secret « \(pendingSecret) » ?")
        }
        .alert(isPresented: $showLoginHint) {
            Alert(title: Text("Se connecter"),
                  message: Text("Va dans l'onglet Profil pour créer/te connecter à un compte."),
                  dismissButton: .default(Text("OK")))
        }
        // --- à remplacer dans SecretSelectionView ---

        .onAppear {
            // Fusionner vm.availableSecrets (venant de Firestore) avec defaultSecrets,
            // en gardant l'ordre de defaultSecrets d'abord, puis les éléments supplémentaires de Firestore.
            let local = defaultSecrets
            let remote = vm.availableSecrets

            // Garde l'ordre : d'abord la liste locale (pour UX/ordre stable),
            // puis tous les éléments distincs de remote qui ne sont pas déjà dans local.
            let extras = remote.filter { !local.contains($0) }
            let merged = local + extras

            // Si merged est vide (improbable car defaultSecrets n'est pas vide), fallback sur local
            vm.availableSecrets = merged.isEmpty ? local : merged
        }


    }
    private func filteredSecrets() -> [String] {
        // Toujours lire depuis vm.availableSecrets (qui contient désormais la liste complète)
        let source = vm.availableSecrets

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return source }

        return source.filter { $0.localizedCaseInsensitiveContains(q) }
    }
    @ViewBuilder
    private func secretRow(secret: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(secret)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                if !vm.isLoggedIn {
                    showLoginHint = true
                    return
                }
                // debug print
                print("DEBUG: pressed choose for:", secret)
                pendingSecret = secret
                showConfirmAlert = true
            } label: {
                Text("Choisir")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!vm.isLoggedIn)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .padding(.horizontal)
    }

//    private func filteredSecrets() -> [String] {
//        let source = vm.availableSecrets
//        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return source }
//        return source.filter { $0.localizedCaseInsensitiveContains(searchText) }
//    }
}
