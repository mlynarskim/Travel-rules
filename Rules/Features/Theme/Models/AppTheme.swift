import SwiftUI
import Foundation

// Główny system kolorów i stylów
struct ThemeManager {
    static let layout = ThemeLayout()
    static let typography = ThemeTypography()
    static let animation = ThemeAnimation()
    
    @AppStorage("selectedTheme") static var currentTheme = ThemeStyle.classic.rawValue
    
    static var colors: ThemeColors {
        switch ThemeStyle(rawValue: currentTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
}

// Background Theme Modifier
struct AppThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    var backgroundImage: String {
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        switch theme {
        case .classic: return colorScheme == .dark ? "imageDark" : "Image"
        case .mountain: return colorScheme == .dark ? "mountain-bg-dark" : "mountain-bg"
        case .beach: return colorScheme == .dark ? "beach-bg-dark" : "beach-bg"
        case .desert: return colorScheme == .dark ? "desert-bg-dark" : "desert-bg"
        case .forest: return colorScheme == .dark ? "forest-bg-dark" : "forest-bg"
        }
    }
    
    func body(content: Content) -> some View {
        ZStack {
            Image(backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .ignoresSafeArea()
            content
        }
    }
}

struct ThemeLayout {
    let cornerRadius = CornerRadii()
    let spacing = Spacing()
    let buttonHeight: CGFloat = 50
    let cardWidth: CGFloat = 340
    let iconSize: CGFloat = 24
}

struct CornerRadii {
    let small: CGFloat = 8
    let medium: CGFloat = 15
    let large: CGFloat = 20
}

struct Spacing {
    let small: CGFloat = 8
    let medium: CGFloat = 16
    let large: CGFloat = 24
}

struct ThemeTypography {
    let title = Font.custom("Lato-Bold", size: 24)
    let headline = Font.custom("Lato-Bold", size: 20)
    let body = Font.custom("Lato-Regular", size: 16)
    let caption = Font.custom("Lato-Regular", size: 14)
}

struct ThemeAnimation {
    let standard = Animation.easeInOut(duration: 0.3)
    let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    let long = Animation.easeInOut(duration: 0.5)
}

struct ModernCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ThemeManager.layout.spacing.medium)
            .background(Color.white.opacity(0.95))
            .cornerRadius(ThemeManager.layout.cornerRadius.medium)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 5,
                x: 0,
                y: 2
            )
    }
}

struct ModernButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ThemeManager.typography.headline)
            .foregroundColor(.white)
            .frame(height: ThemeManager.layout.buttonHeight)
            .background(ThemeManager.colors.primary)
            .cornerRadius(ThemeManager.layout.cornerRadius.medium)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 5,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func appTheme() -> some View {
        self.modifier(AppThemeModifier())
    }
    
    func modernCard() -> some View {
        modifier(ModernCard())
    }
    
    func modernButton() -> some View {
        modifier(ModernButton())
    }
}
