// RulesListViewController.swift
// główny widok z zakładkami

import Foundation
import SwiftUI
import Darwin

struct RulesListView: View {
    // MARK: - AppStorage
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"

    // MARK: - Motyw
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:   return .classicTheme
        case .mountain:  return .mountainTheme
        case .beach:     return .beachTheme
        case .desert:    return .desertTheme
        case .forest:    return .forestTheme
        case .autumn:   return .autumnTheme
        case .winter:   return .winterTheme
            case .spring:   return .springTheme
            case .summer:   return .summerTheme

        }
    }

    // MARK: - State
    @State private var selectedSegment = 0

    var body: some View {
        ZStack {
            backgroundImageView
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer().frame(height: 90)

                let controlWidth = min(UIScreen.main.bounds.width * 0.90, 520)

                Picker("", selection: $selectedSegment) {
                    Text("saved_rules".appLocalized).tag(0)
                    Text("my_rules".appLocalized).tag(1)
                }
                .pickerStyle(.segmented)
                .tint(themeColors.primary)
                .frame(width: controlWidth, height: 32)
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.primary.opacity(0.7))
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: themeColors.cardShadow, radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                TabView(selection: $selectedSegment) {
                    SavedRulesView().tag(0)
                    MyRulesView().tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }

        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ThemeChanged"))) { _ in
            updateBackgroundImage()
        }
    }

    // MARK: - Background Image
    private var backgroundImageView: some View {
        let imageName: String
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:   imageName = isDarkMode ? "classic-bg-dark" : "theme-classic-preview"
        case .mountain:  imageName = isDarkMode ? "mountain-bg-dark" : "theme-mountain-preview"
        case .beach:     imageName = isDarkMode ? "beach-bg-dark" : "theme-beach-preview"
        case .desert:    imageName = isDarkMode ? "desert-bg-dark" : "theme-desert-preview"
        case .forest:    imageName = isDarkMode ? "forest-bg-dark" : "theme-forest-preview"
        case .autumn:    imageName =    isDarkMode ? "autumn-bg-dark" : "theme-autumn-preview"
        case .spring:    imageName = isDarkMode ? "spring-bg-dark" : "theme-spring-preview"
        case .winter:    imageName = isDarkMode ? "winter-bg-dark" : "theme-winter-preview"
        case .summer:    imageName = isDarkMode ? "summer-bg-dark" : "theme-summer-preview"
            
        }
        return Image(imageName)
            .resizable()
            .scaledToFill()
    }

    // MARK: - Update tła
    private func updateBackgroundImage() {
        _ = themeColors.primary
    }
}
