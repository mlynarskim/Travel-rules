struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requiredCount: Int
    var isUnlocked: Bool
}

extension Achievement {
    static let achievements: [Achievement] = [
        // Podstawowe osiągnięcia
        Achievement(id: "first_rule", title: "Początkujący Podróżnik", description: "Wylosuj pierwszą zasadę", icon: "star.fill", requiredCount: 1, isUnlocked: false),
        Achievement(id: "five_rules", title: "Regularny Podróżnik", description: "Wylosuj 5 zasad", icon: "star.circle.fill", requiredCount: 5, isUnlocked: false),
        Achievement(id: "twenty_rules", title: "Doświadczony Podróżnik", description: "Wylosuj 20 zasad", icon: "star.circle.fill", requiredCount: 20, isUnlocked: false),
        
        // Osiągnięcia za zapisywanie
        Achievement(id: "save_first", title: "Kolekcjoner", description: "Zapisz pierwszą zasadę", icon: "bookmark.fill", requiredCount: 1, isUnlocked: false),
        Achievement(id: "save_ten", title: "Zapalony Kolekcjoner", description: "Zapisz 10 zasad", icon: "bookmark.circle.fill", requiredCount: 10, isUnlocked: false),
        
        // Osiągnięcia za aktywność
        Achievement(id: "daily_streak_3", title: "Wytrwały", description: "Używaj aplikacji przez 3 dni z rzędu", icon: "flame.fill", requiredCount: 3, isUnlocked: false),
        Achievement(id: "daily_streak_7", title: "Konsekwentny", description: "Używaj aplikacji przez 7 dni z rzędu", icon: "flame.circle.fill", requiredCount: 7, isUnlocked: false),
        Achievement(id: "daily_streak_30", title: "Mistrz Konsekwencji", description: "Używaj aplikacji przez 30 dni z rzędu", icon: "crown.fill", requiredCount: 30, isUnlocked: false),
        
        // Osiągnięcia za korzystanie z funkcji
        Achievement(id: "first_share", title: "Społeczny Podróżnik", description: "Udostępnij pierwszą zasadę", icon: "square.and.arrow.up", requiredCount: 1, isUnlocked: false),
        Achievement(id: "first_location", title: "Odkrywca", description: "Zapisz pierwszą lokalizację", icon: "mappin.circle.fill", requiredCount: 1, isUnlocked: false)
    ]
}
