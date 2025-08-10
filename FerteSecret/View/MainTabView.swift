//
//  MainTabView.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//


// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        TabView {
            CodeEntryView(vm: vm)
                .tabItem { Label("Accueil", systemImage: "house") }
            RulesView()
                .tabItem { Label("Règles", systemImage: "book") }
            ProfileView(vm: vm)
                .tabItem { Label("Profil", systemImage: "person.circle") }
        }
    }
}
