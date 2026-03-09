import SwiftUI
import GoogleMobileAds
import UserNotifications
//import Firebase
//import GoogleSignIn
import BackgroundTasks

// MARK: - Wspólna funkcja czyszcząca badge (iOS 16 / 17+)
extension UIApplication {
    static func clearBadge() {
        if #available(iOS 17, *) {
            UNUserNotificationCenter.current()
                .setBadgeCount(0) { error in
                    if let error = error {
                        print("❌ Nie udało się wyczyścić badge: \(error.localizedDescription)")
                    }
                }
        } else {
            // 🗑️ deprecated w iOS 17, ale potrzebne dla iOS 16
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // ✅ Inicjalizacja Firebase
        // FirebaseApp.configure()
        // print("✅ Firebase skonfigurowany poprawnie")

        // ✅ Inicjalizacja Google Mobile Ads
        MobileAds.shared.start(completionHandler: nil)

        // ✅ Sprawdzenie App ID Google Ads
        if let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String {
            print("✅ Google Ads initialized with App ID: \(appID)")
        } else {
            print("❌ Brak identyfikatora aplikacji Google Ads w Info.plist")
        }

        // ✅ Ustawienie delegata powiadomień
        UNUserNotificationCenter.current().delegate = self

        // ✅ Wyczyść badge przy starcie
        UIApplication.clearBadge() // zastępuje applicationIconBadgeNumber

        // ✅ Rejestracja zadań w tle
        registerBackgroundTasks()
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized: Bool
            if #available(iOS 16.0, *) {
                authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            } else {
                authorized = settings.authorizationStatus == .authorized
            }
            if authorized, UserDefaults.standard.bool(forKey: "isNotificationEnabled") {
                self.scheduleDailyRandomRuleNotificationAppWide() // harmonogram z losową zasadą
            }
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // ✅ Wyczyść badge po powrocie do aplikacji
        UIApplication.clearBadge() // zastępuje applicationIconBadgeNumber
    }

    // ✅ Rejestracja zadań w tle (BGTaskScheduler)
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.travelrules.app.refresh", using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    // ✅ Obsługa aktualizacji w tle
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleNextBackgroundRefresh()
        print("⏳ Wykonywanie zadania w tle...")
        task.setTaskCompleted(success: true)
    }

    // ✅ Harmonogram dla następnego zadania w tle
    private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.travelrules.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Zaplanowano kolejne zadanie w tle")
        } catch {
            print("❌ Nie udało się zaplanować zadania w tle: \(error.localizedDescription)")
        }
    }

    // ✅ Obsługa powiadomień push
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list, .badge]) // pokazuj baner również w foreground
    }
    
    // App-wide scheduler to ensure dzienne powiadomienie działa nawet bez wchodzenia w PushView
    private func scheduleDailyRandomRuleNotificationAppWide() {
        let content = UNMutableNotificationContent()
        content.title = "daily_rule_notification_title".appLocalized
        content.body = randomRuleForCurrentLanguageAppWide()
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_rule_notification", content: content, trigger: trigger)

        // usuń poprzedni harmonogram o tym samym ID aby uniknąć duplikatów
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_rule_notification"])
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("daily_rule_notification_error".appLocalized, error)
            }
        }
    }

    // Wybór losowej zasady z pamięci (te same tablice: RulesList / PL / ES)
    private func randomRuleForCurrentLanguageAppWide() -> String {
        let code = currentLanguageCodeNormalized()
        let fallback = String(localized: "random_rule_fallback")
        switch code {
        case "pl":
            return RulesListPL.randomElement() ?? fallback
        case "es":
            return RulesListES.randomElement() ?? fallback
        default:
            return rulesListEN.randomElement() ?? fallback
        }
    }

    // Normalizacja kodu języka do pierwszego subtagu (np. "en-US" -> "en")
    private func currentLanguageCodeNormalized() -> String {
        if let selected = UserDefaults.standard.string(forKey: "selectedLanguageCode") {
            return selected.components(separatedBy: CharacterSet(charactersIn: "-_")).first ?? selected
        }
        let sysCode = Locale.current.language.languageCode?.identifier ?? "pl"
        return sysCode.components(separatedBy: CharacterSet(charactersIn: "-_")).first ?? sysCode
    }
}

@main
struct RulesApp: App {
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // ✅ Prośba o zgodę na powiadomienia
        DispatchQueue.main.async {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
                .onAppear {
                    UIApplication.clearBadge()
                }
        }
    }
}
