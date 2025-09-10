//
//  LoginView.swift
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var vm: GameViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isRegisterMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // quick
    @State private var quickName = ""
    @State private var quickSecret = ""

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView {
                VStack(spacing: 16) {
                    Text(isRegisterMode ? "Créer un compte" : "Se connecter")
                        .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
                        .padding(.top, 40)

                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                            .textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)

                        SecureField("Mot de passe", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)

                        if isRegisterMode {
                            TextField("Pseudo", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)
                        }
                    }

                    if let err = errorMessage {
                        Text(err).foregroundColor(.yellow).padding(.horizontal)
                    }

                    Button(action: submitAuth) {
                        Text(isRegisterMode ? "Créer" : "Se connecter")
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#E286CA"), Color(hex: "#BD3993")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white).cornerRadius(12).padding(.horizontal)
                    }
                    .disabled(email.isEmpty || password.isEmpty || (isRegisterMode && username.isEmpty))

                    Button(action: { isRegisterMode.toggle() }) {
                        Text(isRegisterMode ? "Déjà un compte ?" : "Pas de compte ? Créer un compte")
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Divider().background(Color.white.opacity(0.2)).padding(.vertical, 14)

                    VStack(spacing: 10) {
                        Text("Création rapide (local)").foregroundColor(.white)
                        TextField("Pseudo local", text: $quickName).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)

                        Menu {
                            ForEach(vm.availableSecrets.isEmpty ? ["Dragon","Chef","Agent"] : vm.availableSecrets, id:\.self) { s in
                                Button(s) { quickSecret = s }
                            }
                        } label: {
                            HStack {
                                Text(quickSecret.isEmpty ? "Choisir un secret (optionnel)" : quickSecret)
                                    .foregroundColor(quickSecret.isEmpty ? Color.white.opacity(0.7) : .white)
                                Spacer()
                                Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.8))
                            }.padding().background(Color.white.opacity(0.06)).cornerRadius(10).padding(.horizontal)
                        }

                        Button(action: submitQuick) {
                            Text("Créer pseudo local").frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.12)).foregroundColor(.white).cornerRadius(12).padding(.horizontal)
                        }
                        .disabled(quickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .onTapGesture { hideKeyboard() }
    }

    private func submitAuth() {
        errorMessage = nil
        isLoading = true
        if isRegisterMode {
            vm.register(email: email, password: password, username: username) { res in
                DispatchQueue.main.async { isLoading = false
                    if case .failure(let err) = res { errorMessage = err.localizedDescription }
                }
            }
        } else {
            vm.login(email: email, password: password) { res in
                DispatchQueue.main.async { isLoading = false
                    if case .failure(let err) = res { errorMessage = err.localizedDescription }
                }
            }
        }
    }

    private func submitQuick() {
        let name = quickName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        vm.createLocalPlayer(username: name, secret: quickSecret.isEmpty ? nil : quickSecret)
        quickName = ""; quickSecret = ""
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
