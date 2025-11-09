//ThemeStyle.swift
import SwiftUI
import Darwin


enum ThemeStyle: String, CaseIterable {
    case classic
    case mountain
    case beach
    case desert
    case forest
    case autumn
    case winter
    case spring
    case summer
    
    var isPremium: Bool {
        switch self {
        case .classic:
            return false
        case .mountain, .beach, .desert, .forest, .autumn, .winter, .spring, .summer:
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
        background: "theme-classic-preview",
        darkBackground: "classic-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color(hex: "#F1F6F7"),
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
        background: "theme-mountain-preview",
        darkBackground: "mountain-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color(hex: "#F2F6FA"),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )
    
    static let beachTheme = ThemeColors(
        primary: Color(hex: "#1B6C8A"),
        secondary: Color(hex: "#e8723f"),
        accent: Color(hex: "#FFD166"),
        background: "theme-beach-preview",
        darkBackground: "beach-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#4E4E4E"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.2),
        cardBackground: Color(hex: "#FFF4E6"),
        overlay: Color.black.opacity(0.3),
        success: Color(hex: "#48A999"),
        warning: Color(hex: "#FF9F1C"),
        error: Color(hex: "#D7263D"), 
        buttonHighlight: Color.white.opacity(0.25)
    )

    
    static let desertTheme = ThemeColors(
        primary: Color(hex: "#C19A6B"),
        secondary: Color(hex: "#FFB347"),
        accent: Color(hex: "#CD853F"),
        background: "theme-desert-preview",
        darkBackground: "desert-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color(hex: "#FFF2E6"),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )
    // Ujednolicenie koloru dolnego menu dla Desert
    static let desertMenuBackgroundLight = Color(hex: "#EEDAC3")
    static let desertMenuBackgroundDark = Color(hex: "#C19A6B")
    
    static let forestTheme = ThemeColors(
        primary: Color(hex: "#2E8B57"),
        secondary: Color(hex: "#4CAF50"),
        accent: Color(hex: "#556B2F"),
        background: "theme-forest-preview",
        darkBackground: "forest-bg-dark",
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#666666"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.1),
        cardBackground: Color(hex: "#EEF5EE"),
        overlay: Color.black.opacity(0.4),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.2)
    )

    // Pełnoekranowe tła używane w SettingsView:
    //  - "autumn_light" (jasny)
    //  - "autumn_dark"  (ciemny)
    // Podglądy motywu (miniatury w pickerze): "theme-autumn-preview" i "autumn-bg-dark".
    static let autumnTheme = ThemeColors(
        // Ciepła, jesienna paleta dostosowana do stylu aplikacji
        primary: Color(hex: "#C75C2F"),          // wypalona pomarańcza (akcent główny)
        secondary: Color(hex: "#E39A3B"),        // bursztynowy/ochra (elementy wtórne)
        accent: Color(hex: "#7A3E2E"),           // rdzawo-brązowy dla przycisków/ikon
        background: "theme-autumn-preview",      // miniatura motywu (Asset Catalog)
        darkBackground: "autumn-bg-dark",        // miniatura dark (Asset Catalog)
        primaryText: Color(hex: "#1A1A1A"),
        secondaryText: Color(hex: "#5A5A5A"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.12),
        cardBackground: Color(hex: "#FFF1E6"),
        overlay: Color.black.opacity(0.35),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.22)
    )
    // Ujednolicenie koloru dolnego menu dla Autumn
    static let autumnMenuBackgroundLight = Color(hex: "#F7D8B6")
    static let autumnMenuBackgroundDark = Color(hex: "#7A3E2E")

    // Pełnoekranowe tła (Asset Catalog) dla sezonów:
    //  - ZIMA:    "winter_light", "winter_dark"
    //  - WIOSNA:  "spring_light", "spring_dark"
    //  - LATO:    "summer_light", "summer_dark"
    // Podglądy w pickerze:
    //  - "theme-winter-preview", "winter-bg-dark"
    //  - "theme-spring-preview", "spring-bg-dark"
    //  - "theme-summer-preview", "summer-bg-dark"
    static let winterTheme = ThemeColors(
        // Chłodna paleta zimowa spójna z UI
        primary: Color(hex: "#3A7CA5"),          // chłodny błękit (akcent)
        secondary: Color(hex: "#9EC9E2"),        // lodowy jasny
        accent: Color(hex: "#2B5C7B"),           // morski dla CTA/ikon
        background: "theme-winter-preview",
        darkBackground: "winter-bg-dark",
        primaryText: Color(hex: "#101820"),
        secondaryText: Color(hex: "#4A6572"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.12),
        cardBackground: Color(hex: "#EFF6FA"),
        overlay: Color.black.opacity(0.30),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.22)
    )
    
    static let springTheme = ThemeColors(
        // Świeża, kontrastowa paleta wiosenna
        primary: Color(hex: "#43A047"),          // żywa zieleń
        secondary: Color(hex: "#A5D6A7"),        // miętowy
        accent: Color(hex: "#00897B"),           // teal
        background: "theme-spring-preview",
        darkBackground: "spring-bg-dark",
        primaryText: Color(hex: "#16352F"),
        secondaryText: Color(hex: "#4F6B66"),
        lightText: .white,
        cardShadow: Color.black.opacity(0.12),
        cardBackground: Color(hex: "#EDF7F1"),
        overlay: Color.black.opacity(0.25),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.22)
    )
    
    static let summerTheme = ThemeColors(
        // Ciepła, naturalna paleta letnia – lekko przyciemniona dla lepszego kontrastu
        primary: Color(hex: "#9BB982"),
        secondary: Color(hex: "#8FAE76"),
        accent: Color(hex: "#D49A3A"),
        background: "theme-summer-preview",
        darkBackground: "summer-bg-dark",
        primaryText: Color(hex: "#182416"),
        secondaryText: Color(hex: "#344430"),
        lightText: .white.opacity(0.92),
        cardShadow: Color.black.opacity(0.14),
        cardBackground: Color(hex: "#D5DDC8"),
        overlay: Color.black.opacity(0.22),
        success: Color(hex: "#4CAF50"),
        warning: Color(hex: "#FFC107"),
        error: Color(hex: "#FF5252"),
        buttonHighlight: Color.white.opacity(0.15)
    )
    
    static func menuBackground(for theme: ThemeStyle, isDarkMode: Bool) -> Color {
        switch theme {
        case .desert:
            return isDarkMode ? desertMenuBackgroundDark : desertMenuBackgroundLight
        case .autumn:
            return isDarkMode ? autumnMenuBackgroundDark : autumnMenuBackgroundLight
        default:
            return ThemeManager.colors.cardBackground
        }
    }
}
