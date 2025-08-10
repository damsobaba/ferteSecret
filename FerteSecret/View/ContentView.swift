//
//  ContentView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 08/08/2025.
//

//  FerteSecretApp.swift
import SwiftUI


//  ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        Group {
            if !vm.isLoggedIn {
                LoginView(vm: vm)
            } else if vm.currentPlayer?.secret == nil {
                SecretSelectionView(vm: vm)
            } else {
                MainTabView(vm: vm)
            }
        }
    }
}
