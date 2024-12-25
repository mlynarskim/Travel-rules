import SwiftUI
import UserNotifications

class NotificationManager {
    static let instance = NotificationManager()
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("OK")
            }
        }
    }
    
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Hey!!"
        content.subtitle = "Check rule for today!"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = 16
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    func resetBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error resetting badge count: \(error)")
            }
        }
    }
}

struct PushView: View {
    @Binding var showPushView: Bool
    @State private var isNotificationEnabled = false
    @State private var isCountingDown = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#DDAA4F")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Spacer()
                        Text("Notification Settings")
                            .font(.title)
                            .padding()
                        Spacer()
                        
                        Button(action: {
                            showPushView = false
                        }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .padding()
                        }
                    }
                    
                    HStack {
                        Toggle("Enable Notifications", isOn: $isNotificationEnabled)
                            .onChange(of: isNotificationEnabled) { oldValue, newValue in
                                if newValue {
                                    NotificationManager.instance.requestAuthorization()
                                    isCountingDown = true
                                    NotificationManager.instance.scheduleNotification()
                                } else {
                                    isCountingDown = false
                                    // Można dodać kod do anulowania powiadomień
                                }
                            }
                            .padding(20)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            NotificationManager.instance.resetBadgeCount()
        }
    }
}
