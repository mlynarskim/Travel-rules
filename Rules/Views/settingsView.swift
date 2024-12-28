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
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.init(red: 0.87, green: 0.67, blue: 0.31))
                VStack {
                    HStack {
                        Spacer()
                        Text("settings".appLocalized)
                            .font(.title)
                            .padding()
                        Spacer()
                        Button(action: {
                            showSettings = false
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .padding()
                        }
                    }
                    
                    VStack {
                        // Przełączniki
                        Toggle("dark_mode".appLocalized, isOn: $isDarkMode)
                            .padding()
                            .foregroundColor(.black)
                        
                        Toggle("music".appLocalized, isOn: $isMusicEnabled)
                            .padding()
                            .foregroundColor(.black)
                            .onChange(of: isMusicEnabled) { oldValue, newValue in
                                if newValue {
                                    playBackgroundMusic()
                                } else {
                                    stopBackgroundMusic()
                                }
                            }
                        
                        // Wybór języka
                        HStack {
                            Text("language".appLocalized)
                                .foregroundColor(.black)
                            Spacer()
                            Picker("", selection: $languageManager.currentLanguage) {
                                ForEach(AppLanguage.allCases, id: \ .self) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: languageManager.currentLanguage) { oldValue, newValue in
                                print("Language changed from \(oldValue) to \(newValue)")
                                // Wymuszamy pełne odświeżenie widoku
                                UIApplication.shared.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                                
                                // Wysyłamy notyfikację o zmianie języka
                                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
                            }
                        }
                        .padding()
                        
                        Button(action: {
                            resetApplication()
                        }) {
                            Text("reset_all_settings".appLocalized)
                                .foregroundColor(.white)
                                .font(.custom("Lato Bold", size: 20))
                                .padding(5)
                                .frame(width: 200, height: 50)
                                .background(Color(hex: "#fc2c03"))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        
                        Divider().padding(.vertical, 10)

                        // Udostępnij aplikację
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                            Text("share_app".appLocalized)
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {
                                // Wklej tutaj link do aplikacji
                                let appLink = "[TUTAJ WKLEJ LINK]"
                                let activityController = UIActivityViewController(activityItems: [appLink], applicationActivities: nil)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let topViewController = windowScene.windows.first?.rootViewController?.topmostViewController() {
                                    topViewController.present(activityController, animated: true, completion: nil)
                                }
                            }) {
                                Text("share".appLocalized)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()

                        // Oceń aplikację w App Store
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                            Text("rate_app".appLocalized)
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {
                                // Wklej tutaj link do App Store
                                if let url = URL(string: "[TUTAJ WKLEJ LINK]") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("rate".appLocalized)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()

                        // Prześlij opinię
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            Text("send_feedback".appLocalized)
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {
                                // Wklej tutaj adres e-mail
                                let email = "example@example.com" // Zmień na swój adres
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("send".appLocalized)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                    }
                    .padding(20)
                    Spacer()
                }
            }
        }
    }

    func resetApplication() {
        let confirmReset = UIAlertController(
            title: "reset_title".appLocalized,
            message: "reset_message".appLocalized,
            preferredStyle: .alert
        )
        
        confirmReset.addAction(UIAlertAction(title: "reset_button".appLocalized, style: .destructive, handler: { _ in
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
                UserDefaults.standard.synchronize()
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let mainWindow = windowScene.windows.first {
                    mainWindow.rootViewController = UIHostingController(rootView: ContentView())
                    mainWindow.makeKeyAndVisible()
                }
            }
        }))
        
        confirmReset.addAction(UIAlertAction(title: "cancel".appLocalized, style: .cancel, handler: nil))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let topViewController = windowScene.windows.first?.rootViewController?.topmostViewController() {
            topViewController.present(confirmReset, animated: true, completion: nil)
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
