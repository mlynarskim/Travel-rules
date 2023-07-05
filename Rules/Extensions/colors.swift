import SwiftUI
import Foundation

extension Color {
    static let lightTheme = LightTheme()
    static let darkTheme = DarkTheme()
}

struct DarkTheme {
    let accentColor = Color("AccentColor")
    let background = Image("Image")
}

struct LightTheme {
    let accentColor = Color("AccentColor")
    let background = Image("Image-night")
}

