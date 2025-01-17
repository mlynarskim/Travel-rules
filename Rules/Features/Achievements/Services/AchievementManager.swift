import SwiftUI
import UserNotifications

class AchievementManager: ObservableObject {
   @Published var achievements: [Achievement] = Achievement.achievements
   @Published var showToast = false
   @Published var currentAchievement: Achievement?
   
   @AppStorage("dailyStreak") private var dailyStreak: Int = 0
   @AppStorage("lastOpenDate") private var lastOpenDate: Double = Date().timeIntervalSince1970
   
   init() {
       self.achievements = Achievement.achievements
       loadAchievements()
       checkDailyStreak()
   }
   
   private func loadAchievements() {
       if let data = UserDefaults.standard.data(forKey: "achievements"),
          let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
           achievements = decoded
       }
   }
   
   private func saveAchievements() {
       if let encoded = try? JSONEncoder().encode(achievements) {
           UserDefaults.standard.set(encoded, forKey: "achievements")
       }
   }
   
   private func checkDailyStreak() {
       let currentDate = Date()
       let lastDate = Date(timeIntervalSince1970: lastOpenDate)
       
       if !Calendar.current.isDate(lastDate, inSameDayAs: currentDate) {
           if Calendar.current.isDate(lastDate, equalTo: currentDate, toGranularity: .day) {
               dailyStreak += 1
               checkStreakAchievements()
           } else {
               dailyStreak = 1
           }
           lastOpenDate = currentDate.timeIntervalSince1970
       }
   }
   
   private func checkStreakAchievements() {
       if dailyStreak == 3 {
           unlockAchievement(id: "daily_streak_3")
       } else if dailyStreak == 7 {
           unlockAchievement(id: "daily_streak_7")
       } else if dailyStreak == 30 {
           unlockAchievement(id: "daily_streak_30")
       }
   }
   
   func checkAchievements(rulesDrawn: Int, rulesSaved: Int) {
       // Rules drawn achievements
       if rulesDrawn >= 1 {
           unlockAchievement(id: "first_rule")
       }
       if rulesDrawn >= 5 {
           unlockAchievement(id: "five_rules")
       }
       if rulesDrawn >= 20 {
           unlockAchievement(id: "twenty_rules")
       }
       
       // Rules saved achievements
       if rulesSaved >= 1 {
           unlockAchievement(id: "save_first")
       }
       if rulesSaved >= 10 {
           unlockAchievement(id: "save_ten")
       }
   }
   
   func unlockAchievement(id: String) {
       if let index = achievements.firstIndex(where: { $0.id == id }),
          !achievements[index].isUnlocked {
           achievements[index].isUnlocked = true
           showAchievementUnlocked(achievements[index])
           saveAchievements()
       }
   }
   
   private func showAchievementUnlocked(_ achievement: Achievement) {
       // Haptic feedback
       HapticManager.shared.notification(type: .success)
       
       // Show notification
       let content = UNMutableNotificationContent()
       content.title = NSLocalizedString("achievement.unlocked.title", comment: "")
       content.body = String(format: NSLocalizedString("achievement.unlocked.message",
                                                     comment: ""),
                           achievement.title)
       content.sound = .default
       
       let request = UNNotificationRequest(identifier: UUID().uuidString,
                                         content: content,
                                         trigger: nil)
       
       UNUserNotificationCenter.current().add(request)
       
       // Show toast
       currentAchievement = achievement
       withAnimation(.spring()) {
           showToast = true
       }
       
       // Hide toast after 3 seconds
       DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
           withAnimation(.spring()) {
               self.showToast = false
           }
       }
   }
}
