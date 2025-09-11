//

//  FerteSecret
//
//  Created by Adam Mabrouki on 10/08/2025.
//


import Foundation
//  Extensions.swift
import SwiftUI


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
