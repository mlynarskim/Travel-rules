import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit

//Top Bbar menu, main view
struct TopMenuView: View {
    @Binding var showSettings: Bool
    @Binding var showPushView: Bool

    var body: some View {
        HStack {
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "list.dash")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            Spacer()
            
            Button(action: {
                showPushView = true
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }

        }
        .padding(.horizontal, 30)
               .padding(.vertical, 5)
        
               .sheet(isPresented: $showSettings) {
                   SettingsView(showSettings: $showSettings)
               }
               .sheet(isPresented: $showPushView) { // Dodaj sheet dla showPushView
                   pushView(showPushView: $showPushView)
        }
    }
}

// Start screen
struct ContentView: View {
    @State private var isPulsating = false
    @State private var animateRules = false
    @State private var animateTravel = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("isMusicEnabled") var isMusicEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Text("TRAVEL")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .font(.custom("Font LATO/Lato-Bold.ttf", size: 50))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80.0)
                        .offset(x: animateTravel ? 0 : -100)
                        .opacity(animateTravel ? 1 : 0)
                        .animation(.easeOut(duration: 1).delay(1), value: animateTravel)
                        .onAppear {
                            withAnimation {
                                animateTravel = true
                            }
                        }
                    Text("RULES")
                        .foregroundColor(.black)
                        .multilineTextAlignment(.trailing)
                        .font(.custom("Font LATO/Lato-Bold.ttf", size: 50))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 60)
                        .offset(x: animateRules ? 0 : 100)
                        .opacity(animateRules ? 1 : 0)
                        .animation(.easeOut(duration: 1).delay(2), value: animateRules)
                        .onAppear {
                            withAnimation {
                                animateRules = true
                            }
                        }
                    VStack{
                        Spacer()
                        Text("An app for everyone who loves the lifestyle of living on wheels. You will find 365 rules to help you prepare for life in an RV or caravan.")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        //                            .frame(maxWidth: .infinity)
                        NavigationLink(destination: NextView()) {
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(Color(hex: "#DDAA4F"))
                                .frame(width: 200, height: 50)
                                .padding(.all, 15)
                            
                                .overlay(
                                    Text("Let's go!")
                                        .font(.custom("Lato Bold", size: 24))
                                        .foregroundColor(.black)
                                )
                                .scaleEffect(isPulsating ? 0.95 : 0.99)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                                        isPulsating = true
                                }
                            }
                        }
                    }
                }
            }
            .onAppear{
                if isMusicEnabled {
                    playBackgroundMusic()
                }
                
            }
        }
    }
}
    
    
// Main screen, view rules, draw, save, bottom menu
struct NextView: View {
    @State private var randomRule: String = ""
    @State private var nextRuleAvailable: Bool = true
    @State private var savedRules: [String] = []
    @State private var buttonPressCount: Int = 0
    @State private var showSettings = false
    @State private var showPushView = false

    @AppStorage("isDarkMode") var isDarkMode = false
    let RulesList = rulesList
    
    var body: some View {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    VStack {
                        TopMenuView(showSettings: $showSettings, showPushView: $showPushView)
                    VStack {
                        Text("The rule for today is:")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 340, height: 40)
                            .background(Color(hex: "#29606D"))
                            .cornerRadius(15)
                        Text(randomRule)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 25.0)
                            .frame(width: 340, height: 200)
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                Button(action: {
                                    shareRule()
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.black)
                                        .font(.system(size: 30))
                                        .padding(8)
                                }
                                .offset(x: 140, y: 70) // Adjust the offset as needed
                            )

                        HStack {
                            if nextRuleAvailable {
                                Button("Draw") {
                                    buttonPressCount += 2
                                    if buttonPressCount <= 5 {
                                        getRandomRule()
                                    } else {
                                        buttonPressCount = 0
                                        displayAlert()
                                    }
                                }
                                .font(.custom("Lato Bold", size: 20))
                                .foregroundColor(.white)
                                .padding(5)
                                .frame(width: 130, height: 50)
                                .background(Color(hex: "#29606D"))
                                .cornerRadius(15)
                                .disabled(savedRules.contains(randomRule))
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            
                            Button("Save") {
                                saveRule()
                            }
                            .foregroundColor(.white)
                            .font(.custom("Lato Bold", size: 20))
                            .padding(5)
                            .frame(width: 130, height: 50)
                            .background(Color(hex: "#29606D"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding()
                   
                        HStack {
                        NavigationLink(destination: AddRuleView()) {
                            RoundedRectangle(cornerRadius: 15)
                                .padding(.all, 5)
                                .foregroundColor(Color(hex: "#DDAA4F"))
                                .frame(width: 85, height: 85)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.black)
                                        .font(.system(size: 40))
                                )
                        }
                        NavigationLink(destination: TravelListView()) {
                            RoundedRectangle(cornerRadius: 15)
                                .padding(.all, 5)
                                .foregroundColor(Color(hex: "#DDAA4F"))
                                .frame(width: 85, height: 85)
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
                                .frame(width: 85, height: 85)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                                .overlay(
                                    Image(systemName: "signpost.right.and.left")
                                    
                                        .foregroundColor(.black)
                                        .font(.system(size: 40))
                                )
                        }
                        NavigationLink(destination: RulesListView(savedRules: savedRules)) {
                            RoundedRectangle(cornerRadius: 15)
                                .padding(.all, 5)
                                .foregroundColor(Color(hex: "#DDAA4F"))
                                .frame(width: 85, height: 85)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                                .overlay(
                                    Image(systemName: "list.star")
                                        .foregroundColor(.black)
                                        .font(.system(size: 40))
                            )
                        }
                    }
                    .frame(maxHeight:
                            .infinity, alignment: .bottom)
                    .padding()
                }
                .onAppear {
                    getRandomRule()
                    limitRuleCount()
                    loadSavedRules()
            }
        }
    }
    func shareRule() {
         guard let image = generateImage() else {
             print("Failed to generate image")
             return
         }
         
         let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
         
         if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let viewController = windowScene.windows.first?.rootViewController {
             viewController.present(activityViewController, animated: true, completion: nil)
         }
     }
     
    func generateImage() -> UIImage? {
        let maxWidth: CGFloat = 300
        let maxHeight: CGFloat = 200
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
        let attributedText = NSAttributedString(string: randomRule, attributes: textAttributes)
        
        let textRect = attributedText.boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        let imageSize = CGSize(width: max(textRect.width + 40, maxWidth), height: max(textRect.height + 40, maxHeight))
        
        let generatedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
            // Ustawienie koloru tła
            UIColor(Color(hex: "#DDAA4F")).setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            
            attributedText.draw(in: CGRect(x: 20, y: 20, width: imageSize.width - 40, height: imageSize.height - 40))
            
            // Dodanie tekstu "[TRAVEL RULES APP]" w prawym dolnym rogu
            let watermarkText = "TRAVEL RULES"
            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(Color(hex: "#29606D"))
            ]
            let watermarkSize = watermarkText.size(withAttributes: watermarkAttributes)
            let watermarkRect = CGRect(x: imageSize.width - watermarkSize.width - 10, y: imageSize.height - watermarkSize.height - 10, width: watermarkSize.width, height: watermarkSize.height)
            watermarkText.draw(in: watermarkRect, withAttributes: watermarkAttributes)
        }
        
        return generatedImage
    }

        func getRandomRule() {
            if savedRules.count == 365 {
                nextRuleAvailable = false
                return
            }
            repeat {
                randomRule = RulesList.randomElement() ?? ""
            } while savedRules.contains(randomRule)
        }
        
        func limitRuleCount() {
            if savedRules.count == 365 {
                nextRuleAvailable = false
            }
        }
        
        func saveRule() {
            if !savedRules.contains(randomRule) {
                savedRules.append(randomRule)
                limitRuleCount()
                saveRules()
            }
        }
        
        func displayAlert() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: "Slow down", message: "Please take your time and consider the rule.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            rootViewController.present(alert, animated: true, completion: nil)
        }
        
        
        func saveRules() {
            let defaults = UserDefaults.standard
            defaults.set(savedRules, forKey: "savedRules")
        }
        
        func loadSavedRules() {
            let defaults = UserDefaults.standard
            if let rules = defaults.array(forKey: "savedRules") as? [String] {
                savedRules = rules
            }
        }
    }
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



