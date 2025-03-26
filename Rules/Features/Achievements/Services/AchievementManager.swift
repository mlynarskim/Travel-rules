// AchievementManager.swift

import SwiftUI
import UserNotifications
import Darwin

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = Achievement.achievements
    @Published var showToast = false
    @Published var currentAchievement: Achievement?
    
    @AppStorage("dailyStreak") private var dailyStreak: Int = 0
    @AppStorage("lastOpenDate") private var lastOpenDate: Double = Date().timeIntervalSince1970
    static let shared = AchievementManager()

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
    
    // Sprawdzanie dziennego streaku
    private func checkDailyStreak() {
        let currentDate = Date()
        let lastDate = Date(timeIntervalSince1970: lastOpenDate)
        
        // Jeśli dzień się zmienił
        if !Calendar.current.isDate(lastDate, inSameDayAs: currentDate) {
            // Sprawdź czy to kolejny dzień z rzędu
            let dayDifference = Calendar.current.dateComponents([.day], from: lastDate, to: currentDate).day ?? 0
            if dayDifference == 1 {
                dailyStreak += 1
            } else {
                dailyStreak = 1
            }
            lastOpenDate = currentDate.timeIntervalSince1970
            checkStreakAchievements()
        }
    }
    
    private func checkStreakAchievements() {
        // Porównujemy dailyStreak z wymaganiami
        if dailyStreak == 3 {
            unlockAchievement(id: "daily_streak_3")
        }
        if dailyStreak == 7 {
            unlockAchievement(id: "daily_streak_7")
        }
        if dailyStreak == 30 {
            unlockAchievement(id: "daily_streak_30")
        }
    }
    
    // Funkcja sprawdzająca osiągnięcia związane z rysowaniem, zapisywaniem, udostępnianiem i lokalizacją
    func checkAchievements(rulesDrawn: Int,
                           rulesSaved: Int,
                           rulesShared: Int,
                           locationsSaved: Int) {
        // Rysowanie:
        if rulesDrawn >= 1 {
            unlockAchievement(id: "first_rule")
        }
        if rulesDrawn >= 5 {
            unlockAchievement(id: "five_rules")
        }
        if rulesDrawn >= 20 {
            unlockAchievement(id: "twenty_rules")
        }
        
        // Zapisywanie:
        if rulesSaved >= 1 {
            unlockAchievement(id: "save_first")
        }
        if rulesSaved >= 10 {
            unlockAchievement(id: "save_ten")
        }
        
        // Udostępnianie:
        if rulesShared >= 1 {
            unlockAchievement(id: "first_share")
        }
        
        // Pierwsza lokalizacja:
        if locationsSaved >= 1 {
            unlockAchievement(id: "first_location")
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
        
        // Lokalne powiadomienie
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("achievement.unlocked.title", comment: "")
        // W treści podstawiamy tytuł osiągnięcia (przetłumaczony w pliku Localizable)
        let localizedTitle = NSLocalizedString(achievement.titleKey, comment: "")
        content.body = String(format: NSLocalizedString("achievement.unlocked.message", comment: ""),
                              localizedTitle)
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
        
        // Wyświetlenie toasta
        currentAchievement = achievement
        withAnimation(.spring()) {
            showToast = true
        }
        
        // Ukrycie toasta po 4 sekundach
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.spring()) {
                self.showToast = false
            }
        }
    }
}
