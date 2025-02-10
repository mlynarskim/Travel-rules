import SwiftUI
import Foundation

struct MyRulesView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"
    @StateObject private var ruleList = RuleList()
    @State private var showingAddRuleView = false
    @State private var showingDeleteAlert = false
    @State private var ruleToDeleteIndex: Int?
    @State private var selectedRule: Rule?
    @State private var showingRuleDetail = false

    var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return .classicTheme
        case .mountain: return .mountainTheme
        case .beach: return .beachTheme
        case .desert: return .desertTheme
        case .forest: return .forestTheme
        }
    }

    var body: some View {
        ZStack {
            Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 90)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(ruleList.rules.indices, id: \.self) { index in
                            RuleItemView(
                                rule: ruleList.rules[index],
                                onDelete: {
                                    ruleToDeleteIndex = index
                                    showingDeleteAlert = true
                                },
                                onOpen: {
                                    selectedRule = ruleList.rules[index]
                                    showingRuleDetail = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                
                VStack {
                    ActionButton(
                        title: "add_custom_rule_button".appLocalized,
                        themeColors: themeColors
                    ) {
                        showingAddRuleView = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                
                .padding(.bottom, 100)
            }
        }
        NavigationLink(destination: AddRuleView { newRule in
                              ruleList.rules.append(newRule)
                          }, isActive: $showingAddRuleView) {
                              EmptyView()
                          
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("delete_rule_title".appLocalized),
                message: Text("delete_rule_message".appLocalized),
                primaryButton: .destructive(Text("delete_button".appLocalized)) {
                    if let index = ruleToDeleteIndex {
                        withAnimation {
                            ruleList.rules.remove(at: index)
                        }
                    }
                },
                secondaryButton: .cancel(Text("cancel_button".appLocalized))
            )
        }
        .alert("rule_details_title".appLocalized, isPresented: $showingRuleDetail, presenting: selectedRule) { rule in
            Button("ok_button".appLocalized, role: .cancel) {}
        } message: { rule in
            Text(rule.description)
        }
    }
}
