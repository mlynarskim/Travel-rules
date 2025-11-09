// AchievementManager.swift
import SwiftUI
import UserNotifications
import UIKit
import Darwin

final class AchievementManager: ObservableObject {
    // Publiczny singleton (jeśli używasz w wielu miejscach)
    static let shared = AchievementManager()

    // Model
    @Published var achievements: [Achievement] = Achievement.achievements
    @Published var showToast = false
    @Published var currentAchievement: Achievement?

    // Streak
    @AppStorage("dailyStreak") private var dailyStreak: Int = 0
    @AppStorage("lastOpenDate") private var lastOpenDate: Double = 0

    // „Pierwsza lokalizacja” – flaga, żeby nie odblokować ponownie
    @AppStorage("firstLocationUnlocked") private var firstLocationUnlocked: Bool = false

    // Prywatna zmienna do przechowywania ostatniej wartości rulesDrawn
    private var lastRulesDrawn: Int = 0

    // MARK: - Init
    init() {
        loadAchievements()
        bootstrapStreakIfNeeded()      // ← start od dnia 1
        checkDailyStreak()              // ← sprawdź ewentualny przeskok dnia

        // Sprawdzaj streak także po powrocie z tła
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkDailyStreak()
        }
    }

    // MARK: - Persistence
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        } else {
            // Jeśli pod kluczem "achievements" nie ma Data lub dekodowanie się nie powiodło,
            // zresetuj do wartości domyślnych i zapisz w poprawnym formacie.
            achievements = Achievement.achievements
            saveAchievements()
        }
    }

    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }

    // MARK: - Streak bootstrap
    private func bootstrapStreakIfNeeded() {
        // Jeśli pierwszy raz uruchamiamy (brak daty) lub streak == 0 -> zacznij od 1 dziś
        if lastOpenDate == 0 || dailyStreak == 0 {
            dailyStreak = 1
            lastOpenDate = Date().timeIntervalSince1970
        }
    }

// MARK: - Daily streak
    private func checkDailyStreak() {
        let now = Date()
        let lastDate = Date(timeIntervalSince1970: lastOpenDate)

        // Jeśli ten sam dzień – wyjście (streak już naliczony)
        if Calendar.current.isDate(lastDate, inSameDayAs: now) {
            return
        }

        // Zmiana dnia – sprawdź różnicę
        let dayDiff = Calendar.current.dateComponents([.day], from: lastDate, to: now).day ?? 0
        if dayDiff == 1 {
            dailyStreak += 1
        } else {
            // przerwa > 1 dnia – zacznij od 1
            dailyStreak = 1
        }
        lastOpenDate = now.timeIntervalSince1970

        checkStreakAchievements()
    }

    private func checkStreakAchievements() {
        if dailyStreak == 3  { unlockAchievement(id: "daily_streak_3") }
        if dailyStreak == 7  { unlockAchievement(id: "daily_streak_7") }
        if dailyStreak == 30 { unlockAchievement(id: "daily_streak_30") }
    }

    // MARK: - Public API do ręcznego sprawdzania
    func checkAchievements(rulesDrawn: Int,
                           rulesSaved: Int,
                           rulesShared: Int,
                           locationsSaved: Int)
    {
        // Aktualizacja ostatniej wartości rulesDrawn
        lastRulesDrawn = rulesDrawn

        // Losowania
        if rulesDrawn == 1  { unlockAchievement(id: "first_rule") }
        if rulesDrawn == 5  { unlockAchievement(id: "five_rules") }
        if rulesDrawn == 20 { unlockAchievement(id: "twenty_rules") }

        // Zapisy
        if rulesSaved >= 1  { unlockAchievement(id: "save_first") }
        if rulesSaved >= 10 { unlockAchievement(id: "save_ten") }

        // Lokalizacje
        if locationsSaved >= 1 { unlockAchievement(id: "first_location") }

        // Udostępnienia – odblokuj dokładnie przy pierwszym share
    }

    /// Wygodny helper – zawołaj po zapisaniu **pierwszej** lokalizacji.
    func recordLocationAdded() {
        guard !firstLocationUnlocked else { return }
        firstLocationUnlocked = true
        unlockAchievement(id: "first_location")
    }

    /// Alternatywa jeśli masz licznik miejsc.
    func recordLocationsCount(_ count: Int) {
        if count >= 1 { recordLocationAdded() }
    }
    
    /// Zawołaj w momencie naciśnięcia przycisku "Udostępnij" (share) na głównym ekranie
    func recordShareAction() {
        unlockAchievement(id: "first_share")
    }

    // MARK: - Odblokowanie
    func unlockAchievement(id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked
        else { return }

        achievements[index].isUnlocked = true
        saveAchievements()
        showAchievementUnlocked(achievements[index])
    }

    private func showAchievementUnlocked(_ achievement: Achievement) {
        // Haptic
        HapticManager.shared.notification(type: .success)

        // Lokalne powiadomienie (poproś o zgodę, jeśli brak)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
            }
        }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("achievement.unlocked.title", comment: "")
        let localizedTitle = NSLocalizedString(achievement.titleKey, comment: "")
        content.body = String(format: NSLocalizedString("achievement.unlocked.message", comment: ""), localizedTitle)
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)

        // Toast
        DispatchQueue.main.async {
            self.currentAchievement = achievement
            withAnimation(.spring()) { self.showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.spring()) { self.showToast = false }
            }
        }
    }
}
