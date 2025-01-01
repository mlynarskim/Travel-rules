import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit

// MARK: - Metrics
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
    @State private var showAchievements = false
    
    var body: some View {
        HStack {
            MenuButton(icon: "list.dash") {
                showSettings = true
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                MenuButton(icon: "trophy.fill") {
                    showAchievements = true
                }
                
                MenuButton(icon: "bell") {
                    showPushView = true
                }
            }
        }
        .padding(.horizontal, AppTheme.layout.spacing.large)
        .padding(.vertical, AppTheme.layout.spacing.small)
        .background(
            Color.white.opacity(0.1)
                .blur(radius: 5)
        )
        .sheet(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
                .transition(.move(edge: .leading))
        }
        .sheet(isPresented: $showPushView) {
            PushView(showPushView: $showPushView)
                .transition(.move(edge: .trailing))
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
    }
}

struct MenuButton: View {
   let icon: String
   let action: () -> Void
   
   var body: some View {
       Button(action: action) {
           Image(systemName: icon)
               .font(.system(size: 24, weight: .semibold))
               .foregroundColor(AppTheme.colors.primaryText)
               .frame(width: 44, height: 44)
               .background(
                   Circle()
                       .fill(Color.white.opacity(0.2))
                       .shadow(color: AppTheme.colors.cardShadow, radius: 5)
               )
       }
   }
}

struct ShareButton: View {
   let action: () -> Void
   
   var body: some View {
       Button(action: action) {
           Image(systemName: "square.and.arrow.up")
               .font(.system(size: 24))
               .foregroundColor(AppTheme.colors.primary)
               .padding(12)
               .background(
                   Circle()
                       .fill(Color.white)
                       .shadow(color: AppTheme.colors.cardShadow, radius: 3)
               )
       }
       .offset(x: ScreenMetrics.adaptiveWidth(32), y: -8)
   }
}

struct MainActionButton: View {
   let title: String
   let icon: String
   let action: () -> Void
   
   var body: some View {
       Button(action: action) {
           HStack {
               Image(systemName: icon)
                   .font(.system(size: 16, weight: .semibold))
               Text(title)
                   .font(AppTheme.typography.headline)
           }
           .foregroundColor(.white)
           .frame(width: ScreenMetrics.adaptiveWidth(32), height: 50)
           .background(
               RoundedRectangle(cornerRadius: AppTheme.layout.cornerRadius.medium)
                   .fill(AppTheme.colors.primary)
                   .shadow(color: AppTheme.colors.cardShadow, radius: 5)
           )
       }
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

struct NextView: View {
    let bannerID = "ca-app-pub-5307701268996147/4702587401"
        @State private var shouldShowAd = false
        private let maxDailyRules = 5 // zmienione z 3 na 5
   @State private var randomRule: String = ""
   @State private var lastDrawnRule: String = ""
   @State private var savedRules: [Int] = []
   @State private var showSettings = false
   @State private var showPushView = false
   @State private var showRulesList = false
   @AppStorage("isDarkMode") var isDarkMode = false
   @AppStorage("lastRulesDate") private var lastRulesDate: Double = Date().timeIntervalSince1970
   @AppStorage("dailyRulesCount") private var dailyRulesCount: Int = 0
   @State private var usedRulesIndices: [Int] = []
   var rulesList: [String] { return getLocalizedRules() }
   @State private var showAlert = false
   @State private var isLoading = false
   @State private var errorMessage: String?
   @State private var showSaveAlert = false
   @State private var saveAlertMessage = ""
   @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var achievementManager = AchievementManager()
    @AppStorage("totalRulesDrawn") private var totalRulesDrawn: Int = 0
    @AppStorage("totalRulesSaved") private var totalRulesSaved: Int = 0
    
    var body: some View {
        LocalizedView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                if achievementManager.showToast, let achievement = achievementManager.currentAchievement {
                                    ToastView(achievement: achievement, isShowing: $achievementManager.showToast)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        .zIndex(1)
                                        .padding(.top, 50)
                                }
                                
                VStack {
                    TopMenuView(showSettings: $showSettings, showPushView: $showPushView)
                    VStack(spacing: AppTheme.layout.spacing.medium) {
                        Text("the_rule_for_today".appLocalized)
                            .font(AppTheme.typography.headline)
                            .foregroundColor(AppTheme.colors.lightText)
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.layout.spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.layout.cornerRadius.medium)
                                    .fill(AppTheme.colors.primary)
                                    .shadow(color: AppTheme.colors.cardShadow, radius: 5)
                            )
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.layout.cornerRadius.medium)
                                .fill(Color.white)
                                .shadow(color: AppTheme.colors.cardShadow, radius: 8)
                            
                            VStack {
                                Text(randomRule)
                                    .font(AppTheme.typography.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppTheme.colors.primaryText)
                                    .padding()
                                
                                if shouldShowAd {
                                    BannerView(adUnitID: bannerID)
                                        .frame(height: 50)
                                        .padding(.horizontal)
                                }
                                
                                Spacer()
                                
                                ShareButton {
                                    shareRule()
                                }
                                .padding(.bottom, 10)
                            }
                        }
                        .frame(width: ScreenMetrics.adaptiveWidth(85), height: ScreenMetrics.adaptiveHeight(25))
                        .padding(.horizontal)
                        
                        HStack {
                            MainActionButton(title: "draw".appLocalized, icon: "dice.fill") {
                                withAnimation(.spring()) {
                                    if dailyRulesCount >= 3 {
                                        showAlert = true
                                        randomRule = lastDrawnRule
                                    } else {
                                        getRandomRule()
                                    }
                                }
                            }
                            
                            MainActionButton(title: "save".appLocalized, icon: "bookmark.fill") {
                                withAnimation(.spring()) {
                                    saveRule()
                                    showRulesList = true
                                }
                            }
                        }
                        .padding(.horizontal)
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
                    title: Text("daily_limit".appLocalized),
                    message: Text("come_back_tomorrow".appLocalized),
                    dismissButton: .default(Text("ok".appLocalized))
                )
            }
            .alert("success".appLocalized, isPresented: $showSaveAlert) {
                Button("ok".appLocalized, role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
            .onAppear {
                loadSavedRules()
                loadUsedRulesIndices()
                loadLastDrawnRule()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            loadLastDrawnRule()
        }
    }
    
    private func saveLastDrawnRule() {
        UserDefaults.standard.set(randomRule, forKey: "lastDrawnRule")
        lastDrawnRule = randomRule
    }
    
    private func loadLastDrawnRule() {
        if let lastRule = UserDefaults.standard.string(forKey: "lastDrawnRule") {
            randomRule = lastRule
            lastDrawnRule = lastRule
        } else {
            let currentRules = getLocalizedRules()
            let allIndices = Set(0..<currentRules.count)
            let usedIndicesSet = Set(usedRulesIndices)
            let availableIndices = allIndices.subtracting(usedIndicesSet)
            
            if availableIndices.isEmpty {
                randomRule = "all_rules_used".appLocalized
                return
            }
            
            if let randomIndex = availableIndices.randomElement() {
                randomRule = currentRules[randomIndex]
                lastDrawnRule = randomRule
                saveLastDrawnRule()
            }
        }
    }
    
    func getRandomRule() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        if !calendar.isDate(Date(timeIntervalSince1970: lastRulesDate), inSameDayAs: currentDate) {
            dailyRulesCount = 0
            lastRulesDate = currentDate.timeIntervalSince1970
        }
        
        let currentRules = getLocalizedRules()
        let allIndices = Set(0..<currentRules.count)
        let usedIndicesSet = Set(usedRulesIndices)
        let availableIndices = allIndices.subtracting(usedIndicesSet)
        
        if availableIndices.isEmpty {
            randomRule = "all_rules_used".appLocalized
            saveLastDrawnRule()
            return
        }
        
        if dailyRulesCount >= maxDailyRules {
            showAlert = true
            randomRule = lastDrawnRule
            return
        }
        
        if let randomIndex = availableIndices.randomElement() {
            randomRule = currentRules[randomIndex]
            if !usedRulesIndices.contains(randomIndex) {
                usedRulesIndices.append(randomIndex)
                saveUsedRulesIndices()
                dailyRulesCount += 1
                saveLastDrawnRule()
                totalRulesDrawn += 1
                achievementManager.checkAchievements(rulesDrawn: totalRulesDrawn, rulesSaved: totalRulesSaved)
                
                // Pokaż reklamę co drugą zasadę
                if dailyRulesCount % 2 == 0 {
                    withAnimation {
                        shouldShowAd = true
                    }
                    // Ukryj reklamę po 5 sekundach
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            shouldShowAd = false
                        }
                    }
                }
            }
        }
    }
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
           
           let watermarkText = "travel_rules".appLocalized
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
   
   func findRuleIndex(_ rule: String) -> Int? {
       if let index = RulesList.firstIndex(of: rule) {
           return index
       }
       if let index = RulesListPL.firstIndex(of: rule) {
           return index
       }
       if let index = RulesListES.firstIndex(of: rule) {
           return index
       }
       return nil
   }
   
    func saveRule() {
        if let index = findRuleIndex(randomRule) {
            if !savedRules.contains(index) {
                savedRules.append(index)
                saveRules()
                getRandomRule()
                totalRulesSaved += 1
                achievementManager.checkAchievements(rulesDrawn: totalRulesDrawn, rulesSaved: totalRulesSaved)
                saveAlertMessage = "rule_saved".appLocalized
                showSaveAlert = true
            } else {
                saveAlertMessage = "rule_exists".appLocalized
                showSaveAlert = true
            }
        }
    }
    private func saveUsedRulesIndices() {
        if let encoded = try? JSONEncoder().encode(usedRulesIndices) {
            UserDefaults.standard.set(encoded, forKey: "usedRulesIndices")
        }
    }
    private func loadUsedRulesIndices() {
        if let data = UserDefaults.standard.data(forKey: "usedRulesIndices"),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            usedRulesIndices = decoded
        }
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
          let decoded = try? JSONDecoder().decode([Int].self, from: data) {
           savedRules = decoded
       }
   }
}

struct BottomNavigationMenu: View {
    @Binding var savedRules: [Int]
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
           RoundedRectangle(cornerRadius: AppTheme.layout.cornerRadius.medium)
               .padding(.all, 5)
               .foregroundColor(AppTheme.colors.secondary)
               .frame(width: ScreenMetrics.adaptiveWidth(20), height: ScreenMetrics.adaptiveWidth(20))
               .shadow(color: AppTheme.colors.cardShadow, radius: 5)
               .overlay(
                   Image(systemName: icon)
                       .foregroundColor(AppTheme.colors.primaryText)
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

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
       ContentView()
           .environment(\.colorScheme, .light)
   }
}
