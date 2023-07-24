import SwiftUI
import UserNotifications

class NotificationManager {
    static let instance = NotificationManager()
    
    func requestAuthorization(){
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) {(success, error) in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("OK")
            }
        }
    }
    func scheduleNotification(){
        let content = UNMutableNotificationContent()
        content.title = "Hey!!"
        content.subtitle = "Check rule for today!"
        content.sound = .default
        content.badge = 1
        
        //        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        
        //calendar
        var dateComponents = DateComponents()
        dateComponents.hour = 16
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
}

struct pushView: View {
    @Binding var showPushView: Bool
    @State private var isNotificationEnabled = false
    @State private var isCountingDown = false // Dodana zmienna stanu isCountingDown
    
    var body: some View {
        NavigationView {
            ZStack{
                Color(hex: "#DDAA4F")
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
                            .onChange(of: isNotificationEnabled) { newValue in
                                if newValue {
                                    NotificationManager.instance.requestAuthorization()
                                    isCountingDown = true // Ustawienie isCountingDown na true, gdy użytkownik włącza powiadomienia
                                    NotificationManager.instance.scheduleNotification() // Uruchomienie odliczania po zgodzie na powiadomienia
                                } else {
                                    isCountingDown = false // Ustawienie isCountingDown na false, gdy użytkownik wyłącza powiadomienia
                                }
                            }
                            .padding(20)

                    }
                            Spacer()
                        
                    }
                    .onAppear {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                }
            }
        }
    }

