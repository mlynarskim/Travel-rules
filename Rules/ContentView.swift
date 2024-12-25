import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit

// Stała do przechowywania wymiarów ekranu
struct ScreenMetrics {
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    
    static func adaptiveWidth(_ percentage: CGFloat) -> CGFloat {
        return screenWidth * (percentage / 100)
    }
    
    static func adaptiveHeight(_ percentage: CGFloat) -> CGFloat {
        return screenHeight * (percentage / 100)
    }
}

struct TopMenuView: View {
    @Binding var showSettings: Bool
    @Binding var showPushView: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring()) {
                    showSettings = true
                }
            }) {
                Image(systemName: "list.dash")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    showPushView = true
                }
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, ScreenMetrics.adaptiveWidth(8))
        .padding(.vertical, 5)
        .sheet(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
                .transition(.move(edge: .leading))
        }
        .sheet(isPresented: $showPushView) {
            PushView(showPushView: $showPushView)
                .transition(.move(edge: .trailing))
        }
    }
}

struct NextView: View {
    @State private var randomRule: String = ""
    @State private var savedRules: [String] = []
    @State private var buttonPressCount: Int = 0
    @State private var showSettings = false
    @State private var showPushView = false
    @State private var showRulesList = false
    @AppStorage("isDarkMode") var isDarkMode = false
    let RulesList = rulesList
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                TopMenuView(showSettings: $showSettings, showPushView: $showPushView)
                VStack {
                    Text("The rule for today is:")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: ScreenMetrics.adaptiveWidth(85), height: ScreenMetrics.adaptiveHeight(5))
                        .background(Color(hex: "#29606D"))
                        .cornerRadius(15)
                        .transition(.scale)
                    
                    Text(randomRule)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ScreenMetrics.adaptiveWidth(6))
                        .frame(width: ScreenMetrics.adaptiveWidth(85), height: ScreenMetrics.adaptiveHeight(25))
                        .background(Color.white)
                        .cornerRadius(15)
                        .overlay(
                            Button(action: {
                                withAnimation {
                                    shareRule()
                                }
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.black)
                                    .font(.system(size: 30))
                                    .padding(8)
                            }
                            .offset(x: ScreenMetrics.adaptiveWidth(30), y: ScreenMetrics.adaptiveHeight(8))
                        )
                        .transition(.slide)
                    
                    HStack {
                        Button("Draw") {
                            withAnimation(.spring()) {
                                buttonPressCount += 2
                                if buttonPressCount <= 5 {
                                    getRandomRule()
                                } else {
                                    buttonPressCount = 0
                                    displayAlert()
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(savedRules.contains(randomRule))
                        
                        Button("Save") {
                            withAnimation(.spring()) {
                                saveRule()
                                showRulesList = true
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                Spacer()
                
                BottomNavigationMenu(savedRules: $savedRules)
            }
            
            if isLoading {
                LoadingView()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Zwolnij"),
                message: Text("Proszę poświęć czas na przemyślenie zasady."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadSavedRules()
            getRandomRule()
        }
    }
    
    // Funkcje obsługi reguł
    func shareRule() {
        guard let image = generateImage() else {
            print("Failed to generate image")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(activityViewController, animated: true)
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
        
        let textRect = attributedText.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        
        let imageSize = CGSize(
            width: max(textRect.width + 40, maxWidth),
            height: max(textRect.height + 40, maxHeight)
        )
        
        let image = UIGraphicsImageRenderer(size: imageSize).image { context in
            UIColor(Color(hex: "#DDAA4F")).setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            
            attributedText.draw(in: CGRect(
                x: 20,
                y: 20,
                width: imageSize.width - 40,
                height: imageSize.height - 40
            ))
            
            let watermarkText = "TRAVEL RULES"
            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(Color(hex: "#29606D"))
            ]
            
            let watermarkSize = watermarkText.size(withAttributes: watermarkAttributes)
            let watermarkRect = CGRect(
                x: imageSize.width - watermarkSize.width - 10,
                y: imageSize.height - watermarkSize.height - 10,
                width: watermarkSize.width,
                height: watermarkSize.height
            )
            
            watermarkText.draw(in: watermarkRect, withAttributes: watermarkAttributes)
        }
        
        return image
    }
    
    func getRandomRule() {
        if Set(RulesList).subtracting(Set(savedRules)).isEmpty {
            randomRule = "Wszystkie zasady zostały już wykorzystane!"
            return
        }
        
        repeat {
            randomRule = RulesList.randomElement() ?? ""
        } while savedRules.contains(randomRule)
    }
    
    func saveRule() {
        if !savedRules.contains(randomRule) {
            savedRules.append(randomRule)
            saveRules()
        }
    }
    
    func displayAlert() {
        showAlert = true
    }
    
    private func saveRules() {
        do {
            let data = try JSONEncoder().encode(savedRules)
            UserDefaults.standard.set(data, forKey: "savedRules")
        } catch {
            showAlert = true
        }
    }
    
    private func loadSavedRules() {
        if let data = UserDefaults.standard.data(forKey: "savedRules"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            savedRules = decoded
        }
    }
}

// Komponenty UI
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Lato Bold", size: 20))
            .foregroundColor(.white)
            .padding(5)
            .frame(width: ScreenMetrics.adaptiveWidth(32), height: 50)
            .background(Color(hex: "#29606D"))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
        }
        .transition(.opacity)
    }
}

struct BottomNavigationMenu: View {
    @Binding var savedRules: [String]
    
    var body: some View {
        HStack {
            NavigationButton(destination: AddRuleView(), icon: "plus")
            NavigationButton(destination: TravelListView(), icon: "checkmark.circle")
            NavigationButton(destination: GPSView(), icon: "signpost.right.and.left")
            NavigationButton(destination: RulesListView(savedRules: $savedRules), icon: "list.star")
        }
        .padding(.horizontal)
    }
}

struct NavigationButton<Destination: View>: View {
    let destination: Destination
    let icon: String
    
    var body: some View {
        NavigationLink(destination: destination) {
            RoundedRectangle(cornerRadius: 15)
                .padding(.all, 5)
                .foregroundColor(Color(hex: "#DDAA4F"))
                .frame(width: ScreenMetrics.adaptiveWidth(20), height: ScreenMetrics.adaptiveWidth(20))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.black)
                        .font(.system(size: 40))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}
