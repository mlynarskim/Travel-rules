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
            id: "save_twenty_five",
            titleKey: "achievement.save_twenty_five.title",
            descriptionKey: "achievement.save_twenty_five.description",
            icon: "bookmark.circle",
            requiredCount: 25,
            isUnlocked: false,
            color: "AchievementGreen"
        ),
        Achievement(
            id: "save_fifty",
            titleKey: "achievement.save_fifty.title",
            descriptionKey: "achievement.save_fifty.description",
            icon: "bookmark.square",
            requiredCount: 50,
            isUnlocked: false,
            color: "AchievementGold"
        ),
        Achievement(
            id: "add_first_custom_rule",
            titleKey: "achievement.add_first_custom_rule.title",
            descriptionKey: "achievement.add_first_custom_rule.description",
            icon: "plus.circle.fill",
            requiredCount: 1,
            isUnlocked: false,
            color: "AchievementBlue"
        ),
        Achievement(
            id: "add_ten_custom_rules",
            titleKey: "achievement.add_ten_custom_rules.title",
            descriptionKey: "achievement.add_ten_custom_rules.description",
            icon: "plus.circle",
            requiredCount: 10,
            isUnlocked: false,
            color: "AchievementPurple"
        ),
        Achievement(
            id: "create_packing_list",
            titleKey: "achievement.create_packing_list.title",
            descriptionKey: "achievement.create_packing_list.description",
            icon: "list.bullet",
            requiredCount: 1,
            isUnlocked: false,
            color: "AchievementOrange"
        ),
        Achievement(
            id: "share_ten_rules",
            titleKey: "achievement.share_ten_rules.title",
            descriptionKey: "achievement.share_ten_rules.description",
            icon: "square.and.arrow.up.fill",
            requiredCount: 10,
            isUnlocked: false,
            color: "AchievementGreen"
        )
    ]
}
