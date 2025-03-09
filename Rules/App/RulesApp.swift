import SwiftUI
import GoogleMobileAds
import UserNotifications
import Firebase
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // ✅ Inicjalizacja Firebase
        FirebaseApp.configure()
        print("✅ Firebase skonfigurowany poprawnie")

        // ✅ Inicjalizacja Google Mobile Ads
        MobileAds.shared.start { status in
            print("✅ Google Mobile Ads SDK initialized")
        }

        
        // ✅ Sprawdzenie, czy GADApplicationIdentifier jest w Info.plist
        if let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String {
            print("✅ Google Ads initialized with App ID: \(appID)")
        } else {
            print("❌ Brak identyfikatora aplikacji Google Ads w Info.plist")
        }

        return true
    }
    
    // ✅ Obsługa powrotu z Google Sign-In (dla iOS 13+)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct RulesApp: App {
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // ✅ Prośba o zgodę na powiadomienia
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("❌ Nie udało się uzyskać zgody na powiadomienia: \(error.localizedDescription)")
                } else {
                    print("✅ Zgoda na powiadomienia: \(granted)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        }
    }
}
