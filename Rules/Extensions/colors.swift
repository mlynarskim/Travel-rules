import SwiftUI
import Foundation

// Główny system kolorów i stylów
struct AppTheme {
    static let colors = ThemeColors()
    static let layout = ThemeLayout()
    static let typography = ThemeTypography()
    static let animation = ThemeAnimation()
}

// Kolory
struct ThemeColors {
    // Główne kolory
    let primary = Color(hex: "#29606D")     // Istniejący kolor z aplikacji
    let secondary = Color(hex: "#DDAA4F")   // Istniejący kolor z aplikacji
    let accent = Color("AccentColor")       // Z asset catalog
    
    // Tła
    let background = Color(hex: "#FFFFFF")
    let cardBackground = Color(hex: "#FFFFFF").opacity(0.95)
    let overlay = Color.black.opacity(0.4)
    
    // Tekst
    let primaryText = Color(hex: "#1A1A1A")
    let secondaryText = Color(hex: "#666666")
    let lightText = Color.white
    
    // Status
    let success = Color(hex: "#4CAF50")
    let warning = Color(hex: "#FFC107")
    let error = Color(hex: "#FF5252")
    
    // Karty i przyciski
    let cardShadow = Color.black.opacity(0.1)
    let buttonHighlight = Color.white.opacity(0.2)
}

// Layout
struct ThemeLayout {
    // Zaokrąglenia
    let cornerRadius = CornerRadii()
    
    // Marginesy
    let spacing = Spacing()
    
    // Wymiary
    let buttonHeight: CGFloat = 50
    let cardWidth: CGFloat = 340
    let iconSize: CGFloat = 24
}

struct CornerRadii {
    let small: CGFloat = 8
    let medium: CGFloat = 15  // Istniejący promień z aplikacji
    let large: CGFloat = 20
}

struct Spacing {
    let small: CGFloat = 8
    let medium: CGFloat = 16
    let large: CGFloat = 24
}

// Typografia
struct ThemeTypography {
    let title = Font.custom("Lato-Bold", size: 24)
    let headline = Font.custom("Lato-Bold", size: 20)
    let body = Font.custom("Lato-Regular", size: 16)
    let caption = Font.custom("Lato-Regular", size: 14)
}

// Animacje
struct ThemeAnimation {
    let standard = Animation.easeInOut(duration: 0.3)
    let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    let long = Animation.easeInOut(duration: 0.5)
}

// Modyfikatory dla komponentów
struct ModernCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.layout.spacing.medium)
            .background(AppTheme.colors.cardBackground)
            .cornerRadius(AppTheme.layout.cornerRadius.medium)
            .shadow(
                color: AppTheme.colors.cardShadow,
                radius: 5,
                x: 0,
                y: 2
            )
    }
}

struct ModernButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.typography.headline)
            .foregroundColor(AppTheme.colors.lightText)
            .frame(height: AppTheme.layout.buttonHeight)
            .background(AppTheme.colors.primary)
            .cornerRadius(AppTheme.layout.cornerRadius.medium)
            .shadow(
                color: AppTheme.colors.cardShadow,
                radius: 5,
                x: 0,
                y: 2
            )
    }
}

// Rozszerzenia dla wygodnego użycia
extension View {
    func modernCard() -> some View {
        modifier(ModernCard())
    }
    
    func modernButton() -> some View {
        modifier(ModernButton())
    }
}

// Zachowujemy istniejącą funkcjonalność dla kompatybilności
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
