import SwiftUI

struct ThemeSelectionView: View {
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isPremium") private var isPremium = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Wybierz motyw")
                    .font(.title)
                    .padding()
                
                ForEach(ThemeStyle.allCases, id: \.self) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isSelected: theme.rawValue == selectedTheme,
                        isPremium: isPremium
                    ) {
                        if !theme.isPremium || isPremium {
                            selectedTheme = theme.rawValue
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }
}

struct ThemePreviewCard: View {
    let theme: ThemeStyle
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(getThemePreviewImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(getThemeName())
                            .font(.headline)
                        if theme.isPremium && !isPremium {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    Text(getThemeDescription())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
            .opacity(theme.isPremium && !isPremium ? 0.6 : 1)
        }
        .disabled(theme.isPremium && !isPremium)
        .padding(.horizontal)
    }
    
    private func getThemeName() -> String {
        switch theme {
        case .classic: return "Klasyczny"
        case .mountain: return "Górski"
        case .beach: return "Plażowy"
        case .desert: return "Pustynny"
        case .forest: return "Leśny"
        }
    }
    
    private func getThemeDescription() -> String {
        switch theme {
        case .classic: return "Standardowy motyw aplikacji"
        case .mountain: return "Inspirowany górskimi wędrówkami"
        case .beach: return "Wakacyjny klimat plaży"
        case .desert: return "Pustynne przestrzenie"
        case .forest: return "Leśne ścieżki"
        }
    }
    
    private func getThemePreviewImage() -> String {
        switch theme {
        case .classic: return "theme-classic-preview"
        case .mountain: return "theme-mountain-preview"
        case .beach: return "theme-beach-preview"
        case .desert: return "theme-desert-preview"
        case .forest: return "theme-forest-preview"
        }
    }
}
