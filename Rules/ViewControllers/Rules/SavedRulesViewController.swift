import Foundation
import UIKit
import SwiftUI

struct SavedRulesView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    @State private var savedRules: [Int] = []
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var ruleToDelete: Int? = nil
    @State private var showRuleDetail = false
    @State private var selectedRule: Rule?
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(savedRules.indices, id: \.self) { index in
                        if let ruleText = getLocalizedRules().safe(savedRules[index]) {
                            RuleItemView(
                                rule: Rule(name: ruleText, description: ""),
                                onDelete: {
                                    ruleToDelete = index
                                    showAlert = true
                                },
                                onOpen: {
                                    selectedRule = Rule(name: ruleText, description: "")
                                    showRuleDetail = true
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color.clear)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("remove_rule_title".appLocalized),
                message: Text("remove_rule_confirmation".appLocalized),
                primaryButton: .destructive(Text("delete".appLocalized)) {
                    if let index = ruleToDelete {
                        savedRules.remove(at: index)
                        saveRulesToUserDefaults()
                    }
                },
                secondaryButton: .cancel(Text("cancel".appLocalized))
            )
        }
        .alert("rule_details".appLocalized, isPresented: $showRuleDetail) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(selectedRule?.name ?? "")
        }
        .onAppear {
            loadSavedRules()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RulesUpdated"))) { _ in
            loadSavedRules()
        }
    }
    
    private func loadSavedRules() {
        if let data = UserDefaults.standard.data(forKey: "savedRules"),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            savedRules = decoded
        }
    }
    
    private func saveRulesToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedRules) {
            UserDefaults.standard.set(encoded, forKey: "savedRules")
            NotificationCenter.default.post(name: Notification.Name("RulesUpdated"), object: nil)
        }
    }
}

extension Array {
    func safe(_ index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
