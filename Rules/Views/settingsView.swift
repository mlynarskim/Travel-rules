import SwiftUI
import Foundation
import AVFoundation

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
    
    var body: some View {
        NavigationView {
            ZStack{
                Color(hex: "#DDAA4F")
                VStack {
                    HStack {
                        Spacer()
                        
                        Text("Settings")
                            .font(.title)
                            .padding()
                        
                        Spacer()
                        
                        // Close button in view
                        Button(action: {
                            showSettings = false
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .padding()
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .padding()
                        .foregroundColor(.black)
                    
                    Toggle("Music", isOn: $isMusicEnabled)
                        .padding()
                        .foregroundColor(.black)
                        .onChange(of: isMusicEnabled) { newValue in
                            if newValue {
                                playBackgroundMusic()
                            } else {
                                stopBackgroundMusic()
                            }
                        }
                    Button(action: {
                        resetApplication()
                    }) {
                        Text("Reset all settings!")
                            .foregroundColor(.white)
                            .font(.custom("Lato Bold", size: 20))
                            .padding(5)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: "#fc2c03"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    func resetApplication() {
        let confirmReset = UIAlertController(title: "Reset All Settings", message: "Are you sure you want to reset all settings?", preferredStyle: .alert)
        
        confirmReset.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmReset.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
                
                // Reset the root view of the main window
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let mainWindow = windowScene.windows.first {
                    if let rootViewController = mainWindow.rootViewController {
                        rootViewController.present(UIHostingController(rootView: ContentView()), animated: true, completion: nil)
                    }
                }
            }
        }))
        
        // Present the alert
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
