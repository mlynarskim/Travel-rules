//RulesListViewController.swift
//głowny widok z zakładkami

import Foundation
import SwiftUI

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
        }
    }
    
    // MARK: - State
    @State private var selectedSegment = 0
    @State private var selectedTab = 1
    
    var body: some View {
           ZStack {
               backgroundImageView
                   .ignoresSafeArea()

               VStack {
                   Spacer()
                       .frame(height: 90) //padding górny listy pod zakładkami
                   
                 
                   HStack(spacing: 0) {
                       Button(action: {
                           withAnimation {
                               selectedSegment = 0
                           }
                       }) {
                           Text("saved_rules".appLocalized)
                               .frame(maxWidth: .infinity)
                               .padding(.vertical, 10)
                               .background(selectedSegment == 0 ?
                                         Color(themeColors.primary) :
                                         Color(themeColors.primary).opacity(0.3))
                               .foregroundColor(selectedSegment == 0 ? .white : .gray)
                       }
                    
                       Button(action: {
                           withAnimation {
                               selectedSegment = 1
                           }
                       }) {
                           Text("my_rules".appLocalized)
                               .frame(maxWidth: .infinity)
                               .padding(.vertical, 10)
                               .background(selectedSegment == 1 ?
                                         Color(themeColors.primary) :
                                         Color(themeColors.primary).opacity(0.3))
                               .foregroundColor(selectedSegment == 1 ? .white : .gray)
                       }
                   }
                   .background(Color(themeColors.primary).opacity(0.1))
                   .cornerRadius(10)
                   .padding(.horizontal)
                   
                   TabView(selection: $selectedSegment) {
                       SavedRulesView()
                           .tag(0)
                       MyRulesView()
                           .tag(1)
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
        case .classic:   imageName = isDarkMode ? "classic-bg-dark" : "classic-bg"
        case .mountain:  imageName = isDarkMode ? "mountain-bg-dark" : "mountain-bg"
        case .beach:     imageName = isDarkMode ? "beach-bg-dark" : "beach-bg"
        case .desert:    imageName = isDarkMode ? "desert-bg-dark" : "desert-bg"
        case .forest:    imageName = isDarkMode ? "forest-bg-dark" : "forest-bg"
        }
        return Image(imageName)
            .resizable()
            .scaledToFill()
    }
    
    // MARK: - Update tła
    private func updateBackgroundImage() {
        // Triggers a UI update when theme changes
        _ = themeColors.primary
    }
}
