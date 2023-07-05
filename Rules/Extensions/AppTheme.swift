//
//  AppTheme.swift
//  Rules
//
//  Created by Mateusz Mlynarski on 14/06/2023.
//

import Foundation
import SwiftUI

struct AppTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        ZStack {
            if colorScheme == .dark {
                Image("image-dark")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.white // Domyślne tło w trybie jasnym
            }
            
            content
        }
    }
}

extension View {
    func appTheme() -> some View {
        self.modifier(AppTheme())
    }
}
