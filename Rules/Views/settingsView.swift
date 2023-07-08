import SwiftUI

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
                    
                    // Reset all user settings
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
                UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: ContentView())
            }
        }))
        
        // Present the alert
        if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topmostViewController() {
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
