import SwiftUI

struct RulesListView: View {
   @State private var selectedRule: Int?
   @State private var showAlert = false
    @Binding var savedRules: [Int]
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
                   VStack(spacing: 12) {
                       ForEach(savedRules, id: \.self) { ruleIndex in
                           if let rule = getTranslatedRule(at: ruleIndex) {
                               RuleRow(rule: rule, onDelete: {
                                   selectedRule = ruleIndex
                                   showAlert = true
                               }, onOpen: {
                                   openRule(ruleIndex)
                               })
                           }
                       }
                   }
                   .padding(.horizontal)
                   .padding(.top, 10)
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
                       if let ruleIndex = selectedRule {
                           deleteRule(ruleIndex)
                       }
                   }
               )
           }
       }
   }
   
   private func getTranslatedRule(at index: Int) -> String? {
       let currentRules = getLocalizedRules()
       guard index < currentRules.count else { return nil }
       return currentRules[index]
   }
   
   private func deleteRule(_ ruleIndex: Int) {
       withAnimation {
           if let index = savedRules.firstIndex(of: ruleIndex) {
               savedRules.remove(at: index)
               saveRulesToUserDefaults()
               print("Rule successfully deleted and saved")
           }
       }
   }
   
   private func saveRulesToUserDefaults() {
       do {
           let data = try JSONEncoder().encode(savedRules)
           UserDefaults.standard.set(data, forKey: "savedRules")
           UserDefaults.standard.synchronize()
       } catch {
           print("Error saving rules: \(error)")
       }
   }
   
   private func openRule(_ ruleIndex: Int) {
       if let translatedRule = getTranslatedRule(at: ruleIndex) {
           let alert = UIAlertController(
               title: "rule".appLocalized,
               message: translatedRule,
               preferredStyle: .alert
           )
           alert.addAction(UIAlertAction(title: "ok".appLocalized, style: .default))
           
           if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController {
               viewController.present(alert, animated: true)
           }
       }
   }
}

struct RuleRow: View {
   let rule: String
   let onDelete: () -> Void
   let onOpen: () -> Void
   
   var body: some View {
       HStack {
           Button(action: onOpen) {
               Text(rule)
                   .font(.custom("Lato Bold", size: 18))
                   .foregroundColor(.white)
                   .lineLimit(1) // Zmienione z 2 na 1
                   .truncationMode(.tail)
                   .multilineTextAlignment(.leading)
                   .padding(.horizontal, 16)
                   .padding(.vertical, 12)
                   .frame(maxWidth: .infinity, alignment: .leading)
           }
           
           Button(action: onDelete) {
               Image(systemName: "trash")
                   .foregroundColor(.red)
                   .padding(.trailing, 16)
           }
       }
       .frame(maxWidth: .infinity, minHeight: 50)
       .background(Color(hex: "#29606D"))
       .cornerRadius(15)
       .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
   }
}

