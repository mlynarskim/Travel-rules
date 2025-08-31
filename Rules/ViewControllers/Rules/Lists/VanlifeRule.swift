// VanlifeRule.swift
// Model + przypisanie kategorii na bazie ID (wspólne dla PL/EN/ES)

import Foundation

enum RuleCategory: String, CaseIterable, Identifiable, Codable, Equatable {
    case technical     = "category.technical"     // 🛠 Techniczne
    case vanlife       = "category.vanlife"       // 🚐 Vanlife & podróż
    case ecology       = "category.ecology"       // 🌿 Ekologia & natura
    case hygiene       = "category.hygiene"       // 🧼 Higiena & zdrowie
    case food          = "category.food"          // 🍽 Jedzenie & kuchnia
    case mindset       = "category.mindset"       // 🧠 Mindset & relacje
    case safety        = "category.safety"        // 🔒 Bezpieczeństwo
    case location      = "category.location"      // 📍 Miejsca & lokalizacja
    case organization  = "category.organization"  // 📦 Organizacja & porządek
    case gear          = "category.gear"          // 🧰 Sprzęt & lifehacki

    var id: String { rawValue }
    var localizedTitle: String { NSLocalizedString(rawValue, comment: "") }
}

struct VanlifeRule: Identifiable, Codable, Equatable {
    let id: Int
    let text: String
    let category: RuleCategory
}

enum VanlifeRulesFactory {

    // NOWE: buduje listę dla dowolnego języka (PL/EN/ES)
    static func build(from rules: [String]) -> [VanlifeRule] {
        rules.enumerated().map { idx, raw in
            let id = extractId(from: raw) ?? (idx + 1)
            let text = stripLeadingNumber(from: raw)
            return VanlifeRule(id: id, text: text, category: categorize(ruleId: id))
        }
    }

    // Zostawione dla kompatybilności z wcześniejszymi wywołaniami
    static func buildPL(from rules: [String]) -> [VanlifeRule] {
        build(from: rules)
    }

    // MARK: - Helpers

    private static func extractId(from text: String) -> Int? {
        let prefix = text.prefix(6)
        let digits = prefix.prefix { $0.isNumber }
        return Int(digits)
    }

    private static func stripLeadingNumber(from text: String) -> String {
        if let dotIdx = text.firstIndex(of: ".") {
            let afterDot = text.index(after: dotIdx)
            return text[afterDot...].trimmingCharacters(in: .whitespaces)
        }
        return text
    }

    // MARK: - Mapowanie kategorii po ID (jedna prawda dla PL/EN/ES)

    private static func categorize(ruleId: Int) -> RuleCategory {
        if (301...350).contains(ruleId) { return .gear }

        let technical: Set<Int> =
            Set(2...15)
            .union([8,9,11,13,95,113,114,117,119,120,144,150,152,171,172,173,174,289,292])

        let safety: Set<Int> =
            [10,21,28,32,33,34,49,50,69,70,132,133,134,135,142,187,195,200,201,204,210,221,227,228,234,251,258,260,261,281]

        let ecology: Set<Int> =
            [24,35,39,59,60,61,77,128,278,279,293,295]

        let hygiene: Set<Int> =
            [4,12,43,66,76,93,104,105,141,190,196,291]

        let food: Set<Int> =
            [30,58,64,91,104,205,262,277]

        let location: Set<Int> =
            [26,31,44,45,46,81,82,83,84,85,87,139,142,143,148,151,156,163,169,170,199,209,213,214,230,281]

        let organization: Set<Int> =
            [92,97,100,106,107,108,140,147,157,158,161,166,167,171,175,176,181,208,223,224,225,232,233,237,239,254,272,275,296]

        let mindset: Set<Int> =
            [1,16,17,18,19,36,41,42,47,51,52,56,57,62,63,65,67,68,71,72,73,74,78,79,80,88,89,96,98,110,111,116,118,121,122,123,124,125,126,127,129,130,131,136,137,138,146,147,153,154,155,156,160,162,164,165,168,171,172,177,178,179,180,182,183,184,185,186,188,189,191,192,193,194,197,198,202,203,205,206,207,211,212,215,216,217,218,219,220,222,226,229,231,235,236,238,240,241,242,243,244,245,246,247,248,249,250,252,253,255,256,257,259,263,264,265,266,267,268,269,270,271,273,274,276,277,278,280,282,283,284,285,286,287,288,290,293,294,295,297,298,299,300]

        if technical.contains(ruleId) { return .technical }
        if safety.contains(ruleId) { return .safety }
        if ecology.contains(ruleId) { return .ecology }
        if hygiene.contains(ruleId) { return .hygiene }
        if food.contains(ruleId) { return .food }
        if location.contains(ruleId) { return .location }
        if organization.contains(ruleId) { return .organization }
        if mindset.contains(ruleId) { return .mindset }
        return .vanlife
    }
}
