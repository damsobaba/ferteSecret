//
//  FerteSecretApp.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 08/08/2025.
//

import SwiftUI

import FirebaseCore

@main
struct FerteSecretApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
