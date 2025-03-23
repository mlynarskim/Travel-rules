//CustomRuleView.swift
//widok dodawania wwlasnej zasady ✅
import Foundation
import SwiftUI
import Darwin

// MARK: - Model
struct Rule: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var description: String
}

// MARK: - ViewModel
class RuleList: ObservableObject {
    @Published var rules = [Rule]() {
        didSet {
            saveRules()
        }
    }
    
    init() {
        loadRules()
    }
    
    func addRule(name: String, description: String) {
        let rule = Rule(name: name, description: description)
        rules.append(rule)
    }
    
    private func saveRules() {
            DispatchQueue.global(qos: .background).async {
                do {
                    let data = try JSONEncoder().encode(self.rules)
                    UserDefaults.standard.set(data, forKey: "rules")
                } catch {
                    print("Failed to save rules: \(error)")
                }
            }
        }
    
    private func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: "rules") else { return }
        do {
            rules = try JSONDecoder().decode([Rule].self, from: data)
        } catch {
            print("Failed to load rules: \(error)")
        }
    }
}


    
// MARK: - Views
struct AddRuleView: View {
    var onSave: (Rule) -> Void
    
    @State private var ruleDescription = ""
    @State private var isTextFieldActive = false
    @State private var isTextEditorActive = false
    
    @Environment(\.dismiss) var dismiss // Nowy sposób zamykania widoku

    @State private var ruleName: String = ""
    @ObservedObject private var ruleList = RuleList()
    
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") var selectedTheme = ThemeStyle.classic.rawValue
    
    var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return .classicTheme
        case .mountain: return .mountainTheme
        case .beach: return .beachTheme
        case .desert: return .desertTheme
        case .forest: return .forestTheme
        }
    }
    
    init(onSave: @escaping (Rule) -> Void) {
        self.onSave = onSave
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    CustomTextField(
                        text: $ruleName,
                        isActive: $isTextFieldActive,
                        placeholder: "rule_name_placeholder".appLocalized,
                        themeColors: themeColors
                    )
                    
                    CustomTextEditor(
                        text: $ruleDescription,
                        isActive: $isTextEditorActive,
                        themeColors: themeColors
                    )
                    
                    ActionButton(title: "add_rule".appLocalized, themeColors: themeColors) {
                        addRule()
                    }
                   // .frame(width: geometry.size.width * 0.9, height: 50)
                    .background(themeColors.primary)
                    .cornerRadius(15)
                    .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(false)
    }
    
    private func addRule() {
        if !ruleName.isEmpty && !ruleDescription.isEmpty {
            let rule = Rule(name: ruleName, description: ruleDescription)
            onSave(rule)
            ruleName = ""
            ruleDescription = ""
            dismiss()
        }
    }
}


// MARK: - Custom Components
struct CustomTextField: View {
    @Binding var text: String
    @Binding var isActive: Bool
    let placeholder: String
    let themeColors: ThemeColors
    
    var body: some View {
        TextField("", text: $text, onEditingChanged: { isActive in
            self.isActive = isActive
        })
        .contentShape(Rectangle())
        .font(.custom("Lato Bold", size: 20))
        .foregroundColor(themeColors.lightText)
        .multilineTextAlignment(.center)
        .frame(width: 340, height: 40)
        .background(themeColors.primary)
        .cornerRadius(15)
        .textFieldStyle(PlainTextFieldStyle())
        .overlay(
            Group {
                if text.isEmpty && !isActive {
                    Text(placeholder)
                        .foregroundColor(themeColors.lightText)
                }
            }
        )
    }
}

struct CustomTextEditor: View {
    @Binding var text: String
    @Binding var isActive: Bool
    let maxCharacters = 150
    let themeColors: ThemeColors
    
    var remainingCharacters: Int {
        maxCharacters - text.count
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(themeColors.primaryText)
                .padding(.all, 15)
                .frame(width: 340, height: 200)
                .background(themeColors.cardBackground)
                .cornerRadius(15)
                .overlay(
                    Group {
                        if text.isEmpty && !isActive {
                            Text("rule_description_placeholder".appLocalized)
                                .foregroundColor(themeColors.secondaryText)
                                .padding(.all, 15)
                        }
                    }
                )
                .onChange(of: text) {
                    if text.count > maxCharacters {
                        text = String(text.prefix(maxCharacters))
                    }
                }
                .onTapGesture {
                    isActive = true
                }
            
            Text(String(format: "remaining_characters".appLocalized, remainingCharacters))
                .font(.caption)
                .foregroundColor(themeColors.lightText)
                .padding(.trailing, 20)
        }
    }
}

struct ActionButton: View {
    let title: String
    let themeColors: ThemeColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(themeColors.lightText)
                .font(.custom("Lato Bold", size: 20))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .frame(width: 340, height: 50)
                .background(themeColors.primary)
                .cornerRadius(15)
                .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
        }
    }
}



extension View {
    func customButtonStyle(themeColors: ThemeColors) -> some View {
        self
            .padding()
            .background(themeColors.primary)
            .cornerRadius(15)
            .shadow(color: themeColors.cardShadow, radius: 5)
    }
}
