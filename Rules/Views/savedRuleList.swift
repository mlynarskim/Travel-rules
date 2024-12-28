import SwiftUI

struct RulesListView: View {
    @State private var selectedRule: String?
    @State private var showAlert = false
    @Binding var savedRules: [String]
    @AppStorage("isDarkMode") var isDarkMode = false
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(savedRules, id: \.self) { rule in
                            RuleRow(rule: rule, onDelete: {
                                selectedRule = rule
                                showAlert = true
                            }, onOpen: {
                                openRule(rule)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationBarTitle("saved_rules".appLocalized, displayMode: .inline)
                .padding(.bottom)
                .frame(maxHeight: .infinity)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("delete_rule".appLocalized),
                    message: Text("delete_rule_confirmation".appLocalized),
                    primaryButton: .cancel(Text("cancel".appLocalized)),
                    secondaryButton: .destructive(Text("delete".appLocalized)) {
                        if let rule = selectedRule {
                            deleteRule(rule)
                        }
                    }
                )
            }
        }
    }
    
    private func deleteRule(_ rule: String) {
        withAnimation {
            if let index = savedRules.firstIndex(of: rule) {
                savedRules.remove(at: index)
                saveRulesToUserDefaults()
                // Opcjonalnie: dodaj informację o pomyślnym usunięciu
                print("Rule successfully deleted and saved")
            }
        }
    } 
    private func saveRulesToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(savedRules)
            UserDefaults.standard.set(data, forKey: "savedRules")
            UserDefaults.standard.synchronize() // Wymuszamy natychmiastowy zapis
        } catch {
            print("Error saving rules: \(error)")
        }
    }
    
    private func openRule(_ rule: String) {
        let alert = UIAlertController(
            title: "rule".appLocalized,
            message: rule,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ok".appLocalized, style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
}

// Wydzielony komponent dla pojedynczego wiersza reguły
struct RuleRow: View {
    let rule: String
    let onDelete: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onOpen) {
                Text(rule)
                    .font(.custom("Lato Bold", size: 20))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.horizontal, 10)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(Color(hex: "#29606D"))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}
