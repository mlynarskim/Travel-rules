//ThemeStyle.swift
import SwiftUI


enum ThemeStyle: String, CaseIterable {
    case classic
    case mountain
    case beach
    case desert
    case forest
    
    var isPremium: Bool {
        switch self {
        case .classic:
            return false
        case .mountain, .beach, .desert, .forest:
            return false
        }
    }
}
struct ThemeColors {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: String
    let darkBackground: String
    
    // Dodane nowe właściwości
    let primaryText: Color
    let secondaryText: Color
    let lightText: Color
    let cardShadow: Color
    let cardBackground: Color
    let overlay: Color
    let success: Color
    let warning: Color
    let error: Color
    let buttonHighlight: Color
    
    static let classicTheme = ThemeColors(
        primary: Color(hex: "#29606D"),
        secondary: Color(hex: "#DDAA4F"),
        accent: Color("AccentColor"),
        background: "classic-bg",
        darkBackground: "classic-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color.white.opacity(0.95),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )
    
    static let mountainTheme = ThemeColors(
        primary: Color(hex: "#2B4C7E"),
        secondary: Color(hex: "#738FA7"),
        accent: Color(hex: "#A8C6FA"),
        background: "mountain-bg",
        darkBackground: "mountain-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color.white.opacity(0.95),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )
    
    static let beachTheme = ThemeColors(
        primary: Color(hex: "#1B6C8A"), // Niebieski inspirowany wodą i niebem
        secondary: Color(hex: "#e8723f"), // Ciepły pomarańczowy z zachodu słońca
        accent: Color(hex: "#FFD166"), // Złoty odcień odbijającego światła na wodzie
        background: "beach-bg",
        darkBackground: "beach-bg-dark",
        primaryText: Color(hex: "#1A1A1A"), // Ciemny dla czytelności
        secondaryText: Color(hex: "#4E4E4E"), // Delikatny kontrast dla subtelnych elementów UI
        lightText: .white,
        cardShadow: Color.black.opacity(0.2),
        cardBackground: Color.white.opacity(0.9),
        overlay: Color.black.opacity(0.3),
        success: Color(hex: "#48A999"), // Turkusowy akcent
        warning: Color(hex: "#FF9F1C"), // Jasny pomarańczowy dla ostrzeżeń
        error: Color(hex: "#D7263D"), // Intensywny czerwony dla błędów
        buttonHighlight: Color.white.opacity(0.25)
    )

    
    static let desertTheme = ThemeColors(
        primary: Color(hex: "#C19A6B"),
        secondary: Color(hex: "#FFB347"),
        accent: Color(hex: "#CD853F"),
        background: "desert-bg",
        darkBackground: "desert-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color.white.opacity(0.95),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )
    
    static let forestTheme = ThemeColors(
        primary: Color(hex: "#2E8B57"),
        secondary: Color(hex: "#4CAF50"),
        accent: Color(hex: "#556B2F"),
        background: "forest-bg",
        darkBackground: "forest-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color.white.opacity(0.95),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )
}
