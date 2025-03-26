import SwiftUI
import Darwin

struct RuleItemView: View {
    let rule: Rule
    let onDelete: () -> Void
    let onOpen: (() -> Void)? // Opcjonalne, dla zasad zapisanych może być nil
    
    private var themeColors: ThemeColors {
        return ThemeManager.colors
    }
    
    var body: some View {
        HStack {
            // Jeśli onOpen istnieje, to nazwa zasady działa jako przycisk
            if let onOpen = onOpen {
                Button(action: onOpen) {
                    Text(rule.name)
                        .font(.headline)
                        .foregroundColor(Color(themeColors.lightText))
                        .lineLimit(1) // Ograniczenie do jednej linii
                        .truncationMode(.tail) // "..." jeśli tekst jest za długi
                        .padding(.leading, 16) // Padding dla lepszego wyglądu
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(rule.name)
                    .font(.headline)
                    .foregroundColor(Color(themeColors.lightText))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(Color(themeColors.accent))
                    .padding(.trailing, 16) // Padding dla przycisku kosza
            }
        }
        //.frame(height: 40) // Stała wysokość komórki
        .padding(.vertical, 8)
        .background(Color(themeColors.primary).opacity(0.9))
        .cornerRadius(15)
        .padding(.horizontal, 10) // Rozciągnięcie na pełną szerokość
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
