import SwiftUI

struct ThemeSelectionView: View {
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isPremium") private var isPremium = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("choose_theme".appLocalized)
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
                        .transition(.scale)
                        .animation(.easeInOut, value: isSelected)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 5)
            .opacity(theme.isPremium && !isPremium ? 0.6 : 1)
        }
        .disabled(theme.isPremium && !isPremium)
        .padding(.horizontal)
    }
    
    private func getThemeName() -> String {
        switch theme {
        case .classic: return "theme_classic".appLocalized
        case .mountain: return "theme_mountain".appLocalized
        case .beach: return "theme_beach".appLocalized
        case .desert: return "theme_desert".appLocalized
        case .forest: return "theme_forest".appLocalized
        }
    }
    
    private func getThemeDescription() -> String {
        switch theme {
        case .classic: return "theme_classic_description".appLocalized
        case .mountain: return "theme_mountain_description".appLocalized
        case .beach: return "theme_beach_description".appLocalized
        case .desert: return "theme_desert_description".appLocalized
        case .forest: return "theme_forest_description".appLocalized
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
