import SwiftUI

struct ThemeSelectionView: View {
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isPremium") private var isPremium = false
    
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                Text("choose_theme".appLocalized)
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: columns, spacing: 16) {
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
                .padding()
            }
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
            VStack {
                if let image = UIImage(named: getThemePreviewImage()) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                        .opacity(theme.isPremium && !isPremium ? 0.5 : 1)
                } else {
                    // Fallback dla braku obrazu
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(Text("Brak podglądu").font(.caption))
                }
                
                Text(getThemeName())
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if theme.isPremium && !isPremium {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 5)
        }
        .disabled(theme.isPremium && !isPremium)
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
