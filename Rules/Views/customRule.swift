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
    @State private var ruleName = ""
    @State private var ruleDescription = ""
    @State private var isRuleListVisible = false
    @State private var selectedRule: Rule? = nil
    @State private var isTextFieldActive = false
    @State private var isTextEditorActive = false
    @ObservedObject private var ruleList = RuleList()
    @AppStorage("isDarkMode") var isDarkMode = false
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Rule Name Input
                CustomTextField(
                    text: $ruleName,
                    isActive: $isTextFieldActive,
                    placeholder: "Name of your rule..."
                )
                
                // Rule Description Input
                CustomTextEditor(
                    text: $ruleDescription,
                    isActive: $isTextEditorActive
                )
                
                // Action Buttons
                HStack(spacing: 20) {
                    ActionButton(title: "ADD") {
                        addRule()
                    }
                    
                    ActionButton(title: "Show Rules") {
                        isRuleListVisible = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
            
            // Rules List Sheet
            if isRuleListVisible {
                CustomRulesListView(
                    ruleList: ruleList,
                    selectedRule: $selectedRule,
                    isVisible: $isRuleListVisible
                )
            }
        }
        .navigationTitle("Your rules")
    }
    
    private func addRule() {
        if !ruleName.isEmpty && !ruleDescription.isEmpty {
            ruleList.addRule(name: ruleName, description: ruleDescription)
            ruleName = ""
            ruleDescription = ""
            isRuleListVisible = true
        }
    }
}

// MARK: - Custom Components
struct CustomTextField: View {
    @Binding var text: String
    @Binding var isActive: Bool
    let placeholder: String
    
    var body: some View {
        TextField("", text: $text, onEditingChanged: { isActive in
            self.isActive = isActive
        })
        .font(.custom("Lato Bold", size: 20))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .frame(width: 340, height: 40)
        .background(Color(hex: "#29606D"))
        .cornerRadius(15)
        .textFieldStyle(PlainTextFieldStyle())
        .overlay(
            Group {
                if text.isEmpty && !isActive {
                    Text(placeholder)
                        .foregroundColor(.white)
                }
            }
        )
    }
}

struct CustomTextEditor: View {
    @Binding var text: String
    @Binding var isActive: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .foregroundColor(.black)
            .padding(.all, 15)
            .frame(width: 340, height: 200)
            .background(Color.white)
            .cornerRadius(15)
            .overlay(
                Group {
                    if text.isEmpty && !isActive {
                        Text("Write description of your rule here...")
                            .foregroundColor(.gray)
                            .padding(.all, 15)
                    }
                }
            )
            .onTapGesture {
                isActive = true
            }
    }
}

struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .font(.custom("Lato Bold", size: 20))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .frame(width: 130, height: 50)
                .background(Color(hex: "#29606D"))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
}

struct CustomRulesListView: View {
    @ObservedObject var ruleList: RuleList
    @Binding var selectedRule: Rule?
    @Binding var isVisible: Bool
    @AppStorage("isDarkMode") var isDarkMode = false
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(ruleList.rules) { rule in
                        CustomRuleRow(
                            rule: rule,
                            onSelect: { selectedRule = rule },
                            onDelete: { removeRule(rule) }
                        )
                    }
                }
                .padding()
            }
        }
        .alert(item: $selectedRule) { rule in
            Alert(
                title: Text(rule.name),
                message: Text(rule.description),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func removeRule(_ rule: Rule) {
        if let index = ruleList.rules.firstIndex(of: rule) {
            selectedRule = nil
            ruleList.rules.remove(at: index)
        }
    }
}

struct CustomRuleRow: View {
    let rule: Rule
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                Text(limitTitle(rule.name))
                    .font(.custom("Lato Bold", size: 20))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
        }
        .frame(width: 340, height: 40)
        .background(Color(hex: "#29606D"))
        .cornerRadius(15)
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
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
