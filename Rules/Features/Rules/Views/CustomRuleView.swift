import Foundation
import SwiftUI

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
        do {
            let data = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(data, forKey: "rules")
        } catch {
            print("Failed to save rules: \(error)")
        }
    }
    
    private func loadRules() {
        guard let data = UserDefaults.standard.data(forKey: "rules") else {
            return
        }
        
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
    @State private var ruleName = ""
    @State private var ruleDescription = ""
    @State private var isRuleListVisible = false
    @State private var selectedRule: Rule? = nil
    @State private var isTextFieldActive = false
    @State private var isTextEditorActive = false
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
                   Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                       .resizable()
                       .aspectRatio(contentMode: .fill)
                       .frame(maxWidth: .infinity)
                       .edgesIgnoringSafeArea(.all)
                   
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
                       
                       HStack(spacing: 20) {
                           ActionButton(title: "add_rule".appLocalized, themeColors: themeColors) {
                               addRule()
                           }
                           
                           ActionButton(title: "show_rules".appLocalized, themeColors: themeColors) {
                               isRuleListVisible = true
                           }
                       }
                   }
                   .padding(.horizontal)
                   .padding(.bottom, 50)
                   
                   if isRuleListVisible {
                       CustomRulesListView(
                           ruleList: ruleList,
                           selectedRule: $selectedRule,
                           isVisible: $isRuleListVisible,
                           themeColors: themeColors
                       )
                   }
               }
               .navigationTitle("your_rules".appLocalized)
           }
       
    
    private func addRule() {
        if !ruleName.isEmpty && !ruleDescription.isEmpty {
            let rule = Rule(name: ruleName, description: ruleDescription)
            onSave(rule)
            ruleName = ""
            ruleDescription = ""
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
                .onChange(of: text) { newValue in
                    if newValue.count > maxCharacters {
                        text = String(newValue.prefix(maxCharacters))
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
                .frame(width: 130, height: 50)
                .background(themeColors.primary)
                .cornerRadius(15)
                .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
        }
    }
}

struct CustomRulesListView: View {
    @ObservedObject var ruleList: RuleList
    @Binding var selectedRule: Rule?
    @Binding var isVisible: Bool
    @AppStorage("isDarkMode") var isDarkMode = false
    let themeColors: ThemeColors
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(ruleList.rules) { rule in
                        CustomRuleRow(
                            rule: rule,
                            themeColors: themeColors,
                            onSelect: { selectedRule = rule },
                            onDelete: { removeRule(rule) }
                        )
                        .transition(.opacity)
                        .animation(.easeInOut, value: ruleList.rules)
                    }
                }
                .padding()
            }
        }
        .alert(item: $selectedRule) { rule in
            Alert(
                title: Text(rule.name),
                message: Text(rule.description),
                dismissButton: .default(Text("ok".appLocalized))
            )
        }
    }
    
    private func removeRule(_ rule: Rule) {
        withAnimation {
            if let index = ruleList.rules.firstIndex(of: rule) {
                selectedRule = nil
                ruleList.rules.remove(at: index)
            }
        }
    }
}

struct CustomRuleRow: View {
    let rule: Rule
    let themeColors: ThemeColors
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                Text(limitTitle(rule.name))
                    .font(.custom("Lato Bold", size: 20))
                    .foregroundColor(themeColors.lightText)
                    .padding(.horizontal, 20)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(themeColors.error)
                    .accessibility(label: Text("delete".appLocalized))
            }
        }
        .frame(width: 340, height: 40)
        .background(
            themeColors.primary
                .opacity(isPressed ? 0.8 : 1.0)
        )
        .cornerRadius(15)
        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1) { isPressing in
            isPressed = isPressing
        } perform: {}
    }
    
    private func limitTitle(_ title: String) -> String {
        let maxTitleLength = 25
        if title.count > maxTitleLength {
            let endIndex = title.index(title.startIndex, offsetBy: maxTitleLength)
            return String(title[..<endIndex]) + "..."
        }
        return title
    }
}

// MARK: - Utilities
struct HapticFeedback {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
