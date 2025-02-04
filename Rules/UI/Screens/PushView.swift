import SwiftUI
import UserNotifications

struct PushView: View {
    @Binding var showPushView: Bool
    @State private var isNotificationEnabled = false
    @State private var isMonthlyReminderEnabled = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @StateObject private var languageManager = LanguageManager.shared
    @State private var viewRefresh = false
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeColors.secondary
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("notification_settings".appLocalized)
                            .font(.title)
                            .foregroundColor(themeColors.primaryText)
                            .padding()
                        Spacer()
                        
                        Button(action: {
                            showPushView = false
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(themeColors.primaryText)
                                .padding()
                        }
                    }
                    
                    VStack(spacing: 20) {
                        Toggle("enable_notifications".appLocalized, isOn: $isNotificationEnabled)
                            .onChange(of: isNotificationEnabled) { oldValue, newValue in
                                if newValue {
                                    NotificationManager.instance.requestAuthorization()
                                    NotificationManager.instance.scheduleNotification()
                                } else {
                                    NotificationManager.instance.removeNotification(identifier: "daily_rule_notification")
                                }
                            }
                            .padding()
                            .tint(themeColors.primary)
                            .foregroundColor(themeColors.primaryText)
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                        
                        Toggle("enable_monthly_reminder".appLocalized, isOn: $isMonthlyReminderEnabled)
                            .onChange(of: isMonthlyReminderEnabled) { oldValue, newValue in
                                if newValue {
                                    NotificationManager.instance.scheduleMonthlyDocumentCheckNotification()
                                } else {
                                    NotificationManager.instance.removeNotification(identifier: "monthly_document_check")
                                }
                            }
                            .padding()
                            .tint(themeColors.primary)
                            .foregroundColor(themeColors.primaryText)
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .onAppear {
                NotificationManager.instance.resetBadgeCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                viewRefresh.toggle()
            }
            .id(viewRefresh)
        }
    }
}

class NotificationManager {
    static let instance = NotificationManager()
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "notification_title".appLocalized
        content.subtitle = "notification_subtitle".appLocalized
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = 17
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_rule_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleMonthlyDocumentCheckNotification() {
        let content = UNMutableNotificationContent()
        content.title = "document_reminder_title".appLocalized
        content.subtitle = "document_reminder_subtitle".appLocalized
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 10
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monthly_document_check",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling monthly document check notification: \(error)")
            }
        }
    }
    
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func resetBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error resetting badge count: \(error)")
            }
        }
    }
}
