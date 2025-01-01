import SwiftUI
import GoogleMobileAds
import UserNotifications

@main
struct RulesApp: App {
   @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
   @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
   
   init() {
       // Wyłącz tryb jasny/ciemny na poziomie systemu
       if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
           windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified
       }
       
       // Prośba o zgodę na powiadomienia
       UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
           print("Notification permission granted: \(granted)")
       }
   }
   
   var body: some Scene {
       WindowGroup {
           ContentView()
               .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
       }
   }
}

class AppDelegate: NSObject, UIApplicationDelegate {
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
       GADMobileAds.sharedInstance().start(completionHandler: nil)
       return true
   }
}
