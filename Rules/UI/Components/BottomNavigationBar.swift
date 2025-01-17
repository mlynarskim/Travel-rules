import Foundation
import SwiftUI

struct BottomNavigationBar: View {
    @Binding var savedRules: [Int]
    @StateObject private var ruleList = RuleList()
    
    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: AddRuleView(onSave: { rule in
                                    if let index = getLocalizedRules().firstIndex(where: { $0 == rule.name }) {
                                        if !savedRules.contains(index) {
                                            savedRules.append(index)
                                            saveRulesToUserDefaults()
                                        }
                                    }
                                    ruleList.addRule(name: rule.name, description: rule.description)
                                })) {
                                    RoundedRectangle(cornerRadius: 15)
                                        .padding(.all, 5)
                                        .foregroundColor(Color(hex: "#DDAA4F"))
                                        .frame(width: 80, height: 80)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.black)
                                                .font(.system(size: 40))
                                        )
                                }
                NavigationLink(destination: PeopleTabView()) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )
                }
                
                NavigationLink(destination: TravelListView()) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )
                }
                
                NavigationLink(destination: GPSView()) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "signpost.right.and.left")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )
                }
                
                NavigationLink(destination: SavedRuleList(savedRules: $savedRules)) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "list.star")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )
                }
            }
            .padding(.horizontal)
        }
    }
    private func saveRulesToUserDefaults() {
            if let encoded = try? JSONEncoder().encode(savedRules) {
                UserDefaults.standard.set(encoded, forKey: "savedRules")
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: NSNotification.Name("RulesUpdated"), object: nil)
            }
        }
    }

