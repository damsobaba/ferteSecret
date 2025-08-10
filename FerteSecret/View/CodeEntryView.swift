//
//  CodeEntryView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//



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
                        Text("Trouve le secret:  lk,dlzk,d")
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
                .confettiCannon(trigger:$confettiTrigger, num:100, rainHeight:600, repetitions:1)
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
