//
//  LoginView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//



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
