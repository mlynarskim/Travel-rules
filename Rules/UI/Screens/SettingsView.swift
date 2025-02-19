import SwiftUI
import Foundation
import AVFoundation
import UIKit

var audioPlayer: AVAudioPlayer?

func playBackgroundMusic() {
    guard let musicURL = Bundle.main.url(forResource: "lofi-ambient-pianoline-116134", withExtension: "mp3") else {
        return
    }
    
    do {
        audioPlayer = try AVAudioPlayer(contentsOf: musicURL)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.play()
    } catch {
        print("Failed to play background music.")
    }
}

func stopBackgroundMusic() {
    audioPlayer?.stop()
    audioPlayer?.currentTime = 0
}

struct SettingsView: View {
    @Binding var showSettings: Bool
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("isMusicEnabled") var isMusicEnabled = true
    @State private var showThemeSelector = false
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667 // iPhone SE, 7, 8
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeColors.secondary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: isSmallDevice ? 10 : 16) {
                        // Header
                        HStack {
                            Spacer()
                            Text("settings".appLocalized)
                                .font(.system(size: isSmallDevice ? 24 : 28, weight: .bold))
                                .foregroundColor(themeColors.primaryText)
                                .padding(.vertical, isSmallDevice ? 8 : 12)
                            Spacer()
                            Button(action: {
                                showSettings = false
                            }) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: isSmallDevice ? 20 : 24))
                                    .foregroundColor(themeColors.primaryText)
                                    .padding()
                            }
                        }
                        
                        VStack(spacing: isSmallDevice ? 16 : 20) {
                            SettingsCard {
                                Toggle("dark_mode".appLocalized, isOn: $isDarkMode)
                                    .foregroundColor(themeColors.primaryText)
                                
                                Toggle("music".appLocalized, isOn: $isMusicEnabled)
                                    .foregroundColor(themeColors.primaryText)
                                    .onChange(of: isMusicEnabled) { _, newValue in
                                        if newValue {
                                            playBackgroundMusic()
                                        } else {
                                            stopBackgroundMusic()
                                        }
                                    }
                            }
                            
                            SettingsCard {
                                Button(action: { showThemeSelector = true }) {
                                    HStack {
                                        Text("themes".appLocalized)
                                            .foregroundColor(themeColors.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.secondaryText)
                                    }
                                }
                                
                                Divider().background(themeColors.secondaryText)
                                
                                HStack {
                                    Text("language".appLocalized)
                                        .foregroundColor(themeColors.primaryText)
                                    Spacer()
                                    Picker("", selection: $languageManager.currentLanguage) {
                                        ForEach(AppLanguage.allCases, id: \.self) { language in
                                            Text(language.displayName).tag(language)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .onChange(of: languageManager.currentLanguage) { _, _ in
                                        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
                                    }
                                }
                            }
                            
                            Button(action: { resetApplication() }) {
                                Text("reset_all_settings".appLocalized)
                                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: isSmallDevice ? 44 : 50)
                                    .background(Color(hex: "#fc2c03"))
                                    .cornerRadius(12)
                                    .shadow(color: themeColors.cardShadow, radius: 4)
                            }
                            .padding(.horizontal)
                            
                            SettingsCard {
                                SettingsButton(
                                    icon: "square.and.arrow.up",
                                    title: "share_app".appLocalized,
                                    action: "share".appLocalized,
                                    iconColor: themeColors.primary,
                                    themeColors: themeColors
                                ) { shareApp() }
                                
                                Divider().background(themeColors.secondaryText)
                                
                                SettingsButton(
                                    icon: "star.fill",
                                    title: "rate_app".appLocalized,
                                    action: "rate".appLocalized,
                                    iconColor: .yellow,
                                    themeColors: themeColors
                                ) { rateApp() }
                                
                                Divider().background(themeColors.secondaryText)
                                
                                SettingsButton(
                                    icon: "envelope.fill",
                                    title: "send_feedback".appLocalized,
                                    action: "send".appLocalized,
                                    iconColor: .red,
                                    themeColors: themeColors
                                ) { sendFeedback() }
                            }
                        }
                        .padding(.horizontal, isSmallDevice ? 12 : 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showThemeSelector) {
            ThemeSelectionView()
        }
    }
    
    private func shareApp() {
        let appLink = "https://apps.apple.com/pl/app/travel-rules/id6451070215?l=pl"
        let activityController = UIActivityViewController(
            activityItems: [appLink],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let topViewController = windowScene.windows.first?.rootViewController {
            topViewController.present(activityController, animated: true)
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id6451070215?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendFeedback() {
        if let url = URL(string: "mlynarski.mateusz@gmail.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetApplication() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController?.topmostViewController() else {
            return
        }
        
        let confirmReset = UIAlertController(
            title: "reset_title".appLocalized,
            message: "reset_message".appLocalized,
            preferredStyle: .alert
        )
        
        confirmReset.addAction(UIAlertAction(
            title: "reset_button".appLocalized,
            style: .destructive,
            handler: { _ in
                UserDefaults.standard.removeObject(forKey: "rules")
                UserDefaults.standard.removeObject(forKey: "savedRules")
                UserDefaults.standard.removeObject(forKey: "usedRulesIndices")
                UserDefaults.standard.removeObject(forKey: "lastDrawnRule")
                UserDefaults.standard.removeObject(forKey: "lastRulesDate")
                UserDefaults.standard.removeObject(forKey: "dailyRulesCount")
                UserDefaults.standard.removeObject(forKey: "totalRulesDrawn")
                UserDefaults.standard.removeObject(forKey: "totalRulesSaved")
                
                UserDefaults.standard.set(false, forKey: "isDarkMode")
                UserDefaults.standard.set(ThemeStyle.classic.rawValue, forKey: "selectedTheme")
                UserDefaults.standard.set(true, forKey: "isMusicEnabled")
                UserDefaults.standard.set("en", forKey: "selectedLanguage")
                
                UserDefaults.standard.synchronize()
                
                self.showSettings = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AppReset"),
                        object: nil
                    )
                    
                    let restartAlert = UIAlertController(
                        title: "reset_complete".appLocalized,
                        message: "please_restart_app".appLocalized,
                        preferredStyle: .alert
                    )
                    
                    restartAlert.addAction(UIAlertAction(
                        title: "ok".appLocalized,
                        style: .default,
                        handler: nil
                    ))
                    
                    rootViewController.present(restartAlert, animated: true)
                }
            }))
        
        confirmReset.addAction(UIAlertAction(
            title: "cancel".appLocalized,
            style: .cancel,
            handler: nil
        ))
        
        rootViewController.present(confirmReset, animated: true)
    }
}

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4)
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let action: String
    let iconColor: Color
    let themeColors: ThemeColors
    let callback: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
            Text(title)
                .foregroundColor(themeColors.primaryText)
            Spacer()
            Button(action: callback) {
                Text(action)
                    .foregroundColor(themeColors.primary)
            }
        }
    }
}

extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topmostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topmostViewController() ?? self
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topmostViewController() ?? self
        }
        return self
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSettings: .constant(true))
            .environment(\.colorScheme, .light)
    }
}
