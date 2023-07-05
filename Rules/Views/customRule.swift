
import Foundation
import SwiftUI


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

struct AddRuleView: View {
    @State private var ruleName = ""
    @State private var ruleDescription = ""
    @State private var isRuleListVisible = false
    @State private var selectedRule: Rule? = nil
    @State private var isTextFieldActive = false
    @State private var isTextEditorActive = false
    @ObservedObject private var ruleList = RuleList()
    @AppStorage("isDarkMode") var isDarkMode = false

    func addRule() {
        if !ruleName.isEmpty && !ruleDescription.isEmpty {
            ruleList.addRule(name: ruleName, description: ruleDescription)
            ruleName = ""
            ruleDescription = ""
            isRuleListVisible = true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    TextField("", text: $ruleName, onEditingChanged: { isActive in
                        isTextFieldActive = isActive
                    })
                    .font(.custom("Lato Bold", size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
//                    .padding(.all, 10)
                    .frame(width: 340, height: 40)
                    .background(Color(hex: "#29606D"))
                    .cornerRadius(15)
                    .textFieldStyle(PlainTextFieldStyle())
                    .overlay(
                        Group {
                            if ruleName.isEmpty && !isTextFieldActive {
                                Text("Name of your rule...")
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .onTapGesture {
                        isTextFieldActive = true
                        
                    }
                    VStack(spacing: 10) {
                        TextEditor(text: $ruleDescription)
                            .font(.body)
                            .foregroundColor(.black)
                            .padding(.all, 15)
                            .frame(width: 340, height: 200)
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                Group {
                                    if ruleDescription.isEmpty && !isTextEditorActive {
                                        Text("Write description of your rule here...")
                                            .foregroundColor(.gray)
                                    }
                                }
                            )
                            .onTapGesture {
                                isTextEditorActive = true
                            }
                    }
                    
                    HStack {
                        Button(action: addRule) {
                            Text("ADD")
                                .foregroundColor(.white)
                                .font(.custom("Lato Bold", size: 20))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .frame(width: 130, height: 50)
                                .background(Color(hex: "29606D"))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            isRuleListVisible = true
                        }) {
                            Text("Show Rules")
                                .foregroundColor(.white)
                                .font(.custom("Lato Bold", size: 20))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .frame(width: 130, height: 50)
                                .background(Color(hex: "29606D"))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
//                        .disabled(ruleList.rules.isEmpty)
                        
                    }

                }
                .padding(.bottom, 100)
                if isRuleListVisible {
                    CustomRulesListView(ruleList: ruleList, selectedRule: $selectedRule)
                        .padding(.top, 40)

                }
            }
        }
        .navigationTitle("Your rules")
    }
}



struct Rule: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var description: String
}


private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct CustomRulesListView: View {
    @ObservedObject var ruleList: RuleList
    @Binding var selectedRule: Rule?
    @State private var isDarkMode = false
    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(.vertical) {
                    VStack {
                        ForEach(ruleList.rules) { rule in
                            HStack {
                                Button(action: {
                                    selectedRule = rule
                                }) {
                                    Text(rule.name)
                                        .font(.custom("Lato Bold", size: 20))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 20.0)
                                }
                                Spacer()
                                    .padding(.horizontal, 10.0)
                                
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20.0)
                                    .onTapGesture {
                                        removeRule(rule)
                                    }
                            }
                        }
                        .frame(width: 340, height: 40.0)
                        .background(Color(hex: "#29606D"))
                        .cornerRadius(15)
                        
                        
                    }
                }
                .padding(.bottom)
                .listStyle(PlainListStyle())
                .frame(maxHeight: 630) //Determining the maximum height of the list
                .onAppear {hideKeyboard()
                }
                .alert(item: $selectedRule) { rule in
                    Alert(
                        title: Text(rule.name),
                        message: Text(rule.description),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
        func removeRule(_ rule: Rule) {
            if let index = ruleList.rules.firstIndex(of: rule) {
                selectedRule = nil
                ruleList.rules.remove(at: index)
            }
        }
    }



