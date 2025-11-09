import Foundation
import UIKit
import UserNotifications
import Swift

class NotificationManager {
    static let instance = NotificationManager()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) { granted, error in
                if let error = error { print("Error: \(error)") }
                completion(granted)
            }
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func checkMonthlyReminderStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let scheduled = requests.contains { $0.identifier == "monthly_document_check" }
            completion(scheduled)
        }
    }
    
    // Dzienne powiadomienie o 11
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Reminder"
        content.subtitle = "Check your daily rule!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 16
        
        let trigger  = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request  = UNNotificationRequest(identifier: "daily_rule_notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // Miesięczne przypomnienie 19-ego o 11
    func scheduleMonthlyDocumentCheckNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Monthly Reminder"
        content.subtitle = "Check your documents!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.day = 19
        dateComponents.hour = 11
        
        let trigger  = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request  = UNNotificationRequest(identifier: "monthly_document_check", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func resetBadgeCount() {
        if #available(iOS 17, *) {
            UNUserNotificationCenter.current()
                .setBadgeCount(0) { error in
                    if let error = error {
                        print("Badge reset error: \(error.localizedDescription)")
                    }
                }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0 // iOS 16
            }
        }
    }
}
