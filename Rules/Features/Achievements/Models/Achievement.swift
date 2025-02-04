import Foundation
import SwiftUI

struct Achievement: Codable, Identifiable {
    let id: String
    let titleKey: String
    let descriptionKey: String
    let icon: String
    let requiredCount: Int
    var isUnlocked: Bool
    let color: String
    
    var title: String {
        NSLocalizedString(titleKey, comment: "")
    }
    
    var description: String {
        NSLocalizedString(descriptionKey, comment: "")
    }
    
    var themeColor: Color {
        Color(color)
    }
}

extension Achievement {
    static let achievements: [Achievement] = [
            Achievement(
            id: "first_rule",
            titleKey: "achievement.first_rule.title",
            descriptionKey: "achievement.first_rule.description",
            icon: "star.fill",
            requiredCount: 1,
            isUnlocked: false,
            color: "AchievementGold"
        ),
        Achievement(
            id: "five_rules",
            titleKey: "achievement.five_rules.title",
            descriptionKey: "achievement.five_rules.description",
            icon: "star.circle.fill",
            requiredCount: 5,
            isUnlocked: false,
            color: "AchievementSilver"
        ),
        Achievement(
            id: "twenty_rules",
            titleKey: "achievement.twenty_rules.title",
            descriptionKey: "achievement.twenty_rules.description",
            icon: "star.circle.fill",
            requiredCount: 20,
            isUnlocked: false,
            color: "AchievementBronze"
        ),
        
        Achievement(
            id: "save_first",
            titleKey: "achievement.save_first.title",
            descriptionKey: "achievement.save_first.description",
            icon: "bookmark.fill",
            requiredCount: 1,
            isUnlocked: false,
            color: "AchievementBlue"
        ),
        Achievement(
            id: "save_ten",
            titleKey: "achievement.save_ten.title",
            descriptionKey: "achievement.save_ten.description",
            icon: "bookmark.circle.fill",
            requiredCount: 10,
            isUnlocked: false,
            color: "AchievementPurple"
        ),
        
        Achievement(
            id: "daily_streak_3",
            titleKey: "achievement.daily_streak_3.title",
            descriptionKey: "achievement.daily_streak_3.description",
            icon: "flame.fill",
            requiredCount: 3,
            isUnlocked: false,
            color: "AchievementRed"
        ),
        Achievement(
            id: "daily_streak_7",
            titleKey: "achievement.daily_streak_7.title",
            descriptionKey: "achievement.daily_streak_7.description",
            icon: "flame.circle.fill",
            requiredCount: 7,
            isUnlocked: false,
            color: "AchievementOrange"
        ),
        Achievement(
            id: "daily_streak_30",
            titleKey: "achievement.daily_streak_30.title",
            descriptionKey: "achievement.daily_streak_30.description",
            icon: "crown.fill",
            requiredCount: 30,
            isUnlocked: false,
            color: "AchievementGold"
        ),
        
        Achievement(
            id: "first_share",
            titleKey: "achievement.first_share.title",
            descriptionKey: "achievement.first_share.description",
            icon: "square.and.arrow.up",
            requiredCount: 1,
            isUnlocked: false,
            color: "AchievementGreen"
        ),
        Achievement(
            id: "first_location",
            titleKey: "achievement.first_location.title",
            descriptionKey: "achievement.first_location.description",
            icon: "mappin.circle.fill",
            requiredCount: 1,
            isUnlocked: false,
            color: "AchievementBlue"
        )
    ]
}
