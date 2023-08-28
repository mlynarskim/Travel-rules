import SwiftUI

struct RulesListView: View {
    @State private var selectedRule: String?
    @State private var showAlert = false
    @Binding var savedRules: [String]
    @AppStorage("isDarkMode") var isDarkMode = false
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            VStack {
                ScrollView(.vertical) {
                    VStack(spacing: 8) {
                        ForEach(savedRules, id: \.self) { rule in
                            HStack {
                                Button(action: {
                                    openRule(rule)
                                }) {
                                    Text(rule)
                                        .font(.custom("Lato Bold", size: 20))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 10.0)
                                }
                                Spacer()
                                Button(action: {
                                    deleteRule(rule)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 10.0)
                                }
                            }
                            .frame(width: 340, height: 40.0)
                            .background(Color(hex: "#29606D"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                }
                .navigationBarTitle("Saved rules")
                .padding(.bottom)
                .listStyle(PlainListStyle())
                .frame(maxHeight: 540) // Determining the maximum height of the list
            }
            .alert(isPresented: $showAlert) {
                if let rule = selectedRule {
                    return Alert(
                        title: Text("Delete Rule"),
                        message: Text("Are you sure you want to delete this rule?"),
                        primaryButton: .cancel(Text("Cancel")),
                        secondaryButton: .destructive(Text("Delete")) {
                            deleteRule(rule)
                        }
                    )
                } else {
                    return Alert(title: Text("Error"))
                }
            }
        }
    }
    
    func deleteRule(_ rule: String) {
        if let index = savedRules.firstIndex(of: rule) {
            savedRules.remove(at: index)
        }
    }
}

func openRule(_ rule: String) {
    // Create an alert to display the rule's content
    let alert = UIAlertController(title: "Rule", message: rule, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    
    // Get the relevant window scene
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let viewController = windowScene.windows.first?.rootViewController {
        viewController.present(alert, animated: true, completion: nil)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
