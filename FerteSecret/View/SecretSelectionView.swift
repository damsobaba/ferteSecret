//
//  SecretSelectionView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//


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
