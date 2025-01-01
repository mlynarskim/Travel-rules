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
            } else {
                dailyStreak = 1
            }
            lastOpenDate = currentDate.timeIntervalSince1970
        }
    }
    
    func checkAchievements(rulesDrawn: Int, rulesSaved: Int) {
        var updated = false
        
        for (index, achievement) in achievements.enumerated() {
            var shouldUnlock = false
            
            switch achievement.id {
            case "first_rule":
                shouldUnlock = rulesDrawn >= 1
            case "five_rules":
                shouldUnlock = rulesDrawn >= 5
            case "save_first":
                shouldUnlock = rulesSaved >= 1
            case "daily_streak":
                shouldUnlock = dailyStreak >= 5
            default:
                break
            }
            
            if shouldUnlock && !achievement.isUnlocked {
                achievements[index].isUnlocked = true
                updated = true
                showAchievementUnlocked(achievement)
            }
        }
        
        if updated {
            saveAchievements()
        }
    }
    
    private func showAchievementUnlocked(_ achievement: Achievement) {
        HapticManager.shared.notification(type: .success)
        currentAchievement = achievement
        
        withAnimation(.spring()) {
            showToast = true
        }
        
        // Ukryj toast po 3 sekundach
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring()) {
                self.showToast = false
            }
        }
    }
}
