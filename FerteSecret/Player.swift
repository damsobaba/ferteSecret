//
//  Player.swift
//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//

//  Player.swift
import Foundation
//  Extensions.swift
import SwiftUI

extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int = UInt64(); Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: (a, r, g, b) = (255, (int>>8)*17, (int>>4&0xF)*17, (int&0xF)*17)
//        case 6: (a, r, g, b) = (255, int>>16, int>>8&0xFF, int&0xFF)
//        case 8: (a, r, g, b) = (int>>24, int>>16&0xFF, int>>8&0xFF, int&0xFF)
//        default: (a, r, g, b) = (255,0,0,0)
//        }
//        self.init(.sRGB,
//                  red: Double(r)/255,
//                  green: Double(g)/255,
//                  blue: Double(b)/255,
//                  opacity: Double(a)/255)
//    }
}

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#E286CA"),
                Color(hex: "#BD3993"),
                Color(hex: "#465FB0")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
