import SwiftUI
import Foundation

struct SavedRuleList: View {
    @Binding var savedRules: [Int]
    @AppStorage("isDarkMode") var isDarkMode = false
    @State private var selectedRuleIndex: Int?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Tło
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                // Lista reguł
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(savedRules.indices, id: \.self) { index in
                            if let rule = getTranslatedRule(at: savedRules[index]) {
                                RuleItemView(
                                    rule: Rule(name: rule, description: ""),
                                    onDelete: {
                                        selectedRuleIndex = savedRules[index]
                                        showAlert = true
                                    },
                                    onOpen: {
                                        showRuleDetail(rule)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom)
                .frame(maxHeight: .infinity)
            }
            // Alert dla usuwania reguły
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .cancel(Text("cancel".appLocalized)),
                    secondaryButton: .destructive(Text("delete".appLocalized)) { if let ruleIndex = selectedRuleIndex { deleteRule(ruleIndex) } }
                )
            }
        }
    }
    
    // Pobranie przetłumaczonej reguły
    private func getTranslatedRule(at index: Int) -> String? {
        let currentRules = getLocalizedRules()
        guard index < currentRules.count else { return nil }
        return currentRules[index]
    }
    
    // Usunięcie reguły
    private func deleteRule(_ ruleIndex: Int) {
        withAnimation {
            if let index = savedRules.firstIndex(of: ruleIndex) {
                savedRules.remove(at: index)
                saveRulesToUserDefaults()
            }
        }
    }
    
    // Zapis reguł do UserDefaults
    private func saveRulesToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(savedRules)
            UserDefaults.standard.set(data, forKey: "savedRules")
        } catch {
            print("Error saving rules: \(error)")
        }
    }
    
    // Wyświetlenie szczegółów reguły
    private func showRuleDetail(_ rule: String) {
        alertTitle = "rule".appLocalized
        alertMessage = rule
        showAlert = true
    }
}
