//
// ContentView.swift
//

import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit
import GoogleMobileAds
import UIKit 

// MARK: - Rewarded Ad Delegate
class RewardedAdDelegate: NSObject, FullScreenContentDelegate {
    var adDidDismiss: (() -> Void)?
    var adDidFail: ((Error) -> Void)?
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
#if DEBUG
        print("✅ Rewarded ad został zamknięty")
#endif
        adDidDismiss?()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
#if DEBUG
        print("❌ Błąd prezentacji rewarded ad: \(error.localizedDescription)")
#endif
        adDidFail?(error)
    }
}

struct ContentView: View {
    @State private var savedRules: [Int] = []
    @State private var showSettings = false
    @State private var showPushView = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isDarkMode") var isDarkMode = false
    
    var backgroundImage: String {
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        switch theme {
        case .classic: return isDarkMode ? "classic-bg-dark" : "theme-classic-preview"
        case .mountain: return isDarkMode ? "mountain-bg-dark" : "theme-mountain-preview"
        case .beach: return isDarkMode ? "beach-bg-dark" : "theme-beach-preview"
        case .desert: return isDarkMode ? "desert-bg-dark" : "theme-desert-preview"
        case .forest: return isDarkMode ? "forest-bg-dark" : "theme-forest-preview"
        case .autumn: return isDarkMode ? "autumn-bg-dark" : "theme-autumn-preview"
        case .spring: return isDarkMode ? "spring-bg-dark" : "theme-spring-preview"
            case .winter: return isDarkMode ? "winter-bg-dark" : "theme-winter-preview"
            case .summer: return isDarkMode ? "summer-bg-dark" : "theme-summer-preview"
        }
    }
    
    var body: some View {
        NavigationView {
            NextView()
                .background(
                    Image(backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ScreenMetrics {
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    
    static func adaptiveWidth(_ percentage: CGFloat) -> CGFloat {
        return screenWidth * (percentage / 100)
    }
    
    static func adaptiveHeight(_ percentage: CGFloat) -> CGFloat {
        return screenHeight * (percentage / 100)
    }
}

struct TopMenuView: View {
    @Binding var showSettings: Bool
    @Binding var showPushView: Bool
    @State private var showAchievements = false
    
    var body: some View {
        HStack {
            MenuButton(icon: "list.dash") {
                showSettings = true
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                MenuButton(icon: "trophy.fill") {
                    showAchievements = true
                }
                MenuButton(icon: "bell") {
                    showPushView = true
                }
            }
        }
        .padding(.horizontal, ThemeManager.layout.spacing.large)
        .padding(.vertical, ThemeManager.layout.spacing.small)
        .background(
            Color.white.opacity(0.1)
                .blur(radius: 5)
        )
        .sheet(isPresented: $showSettings) {
            SettingsView(showSettings: $showSettings)
                .transition(.move(edge: .leading))
        }
        .sheet(isPresented: $showPushView) {
            PushView(showPushView: $showPushView)
                .transition(.move(edge: .trailing))
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .transition(.move(edge: .bottom))
        }
    }
}

struct MenuButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(ThemeManager.colors.primaryText)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .shadow(color: ThemeManager.colors.cardShadow, radius: UIScreen.main.nativeBounds.height <= 1334 ? 2 : 5)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ShareButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 22))
                .foregroundColor(ThemeManager.colors.primary)
                .padding(14)
        }
        .offset(x: ScreenMetrics.adaptiveWidth(32), y: -8)
        .buttonStyle(.plain)
    }
}

struct MainActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(ThemeManager.typography.headline)
            }
            .foregroundColor(.white)
            .frame(width: ScreenMetrics.adaptiveWidth(32), height: 50)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.layout.cornerRadius.medium)
                    .fill(ThemeManager.colors.primary)
                    .shadow(color: ThemeManager.colors.cardShadow, radius: UIScreen.main.nativeBounds.height <= 1334 ? 2 : 5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
        }
        .transition(.opacity)
    }
}

struct NextView: View {
    let bannerID = "ca-app-pub-5307701268996147~2371937539"
    let bannerAdUnitID = "ca-app-pub-5307701268996147/4702587401"
    let rewardedAdUnitID = "ca-app-pub-5307701268996147/8131308249"
    
    @State private var shouldShowAd = false
    private let maxDailyRules = 5
    @State private var randomRule: String = ""
    @State private var lastDrawnRule: String = ""
    @State private var savedRules: [Int] = []
    @State private var showSettings = false
    @State private var showPushView = false
    @State private var showRulesList = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    // 🟡 PREMIUM
    @AppStorage("hasPremium") private var hasPremium: Bool = false
    
    // 🕒 przechowywanie daty oraz limitu dziennego
    @AppStorage("lastRulesDate") private var lastRulesDate: Double = 0
    @AppStorage("dailyRulesCount") private var dailyRulesCount: Int = 0
    
    @State private var usedRulesIndices: [Int] = []
    var rulesList: [String] { return getLocalizedRules() }
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var achievementManager = AchievementManager()
    @AppStorage("totalRulesDrawn") private var totalRulesDrawn: Int = 0
    @AppStorage("totalRulesSaved") private var totalRulesSaved: Int = 0
    @AppStorage("rewardedPacks") private var rewardedPacks: Int = 0
    @State private var rewardedAd: RewardedAd?
    @State private var rewardedAdDelegate = RewardedAdDelegate()
    @AppStorage("totalRulesShared") private var totalRulesShared: Int = 0

    // 🔧 Wydajność: prosty wskaźnik „starszego” urządzenia (iPhone 7/8/SE)
    private var isLowEndDevice: Bool {
        UIScreen.main.nativeBounds.height <= 1334
    }

    // [KATEGORIE]
    @AppStorage("selectedCategoryKey") private var selectedCategoryKey: String = "all"
    // ⚠️ [ZMIANA] usunięto użycie @AppStorage("appLanguage") na rzecz LanguageManager (spójność z SettingsView)
    // @AppStorage("appLanguage") private var appLanguageCode: String = Locale.current.language.languageCode?.identifier ?? "pl" // ← nieużywane (pozostawiono komentarz)
    @State private var categorizedAllRules: [VanlifeRule] = []
    
    // klucz per kategoria
    private var usedIndicesStorageKey: String { "usedRulesIndices_\(selectedCategoryKey)" }
    
    // Limit dzienny: Premium = bez limitu (Int.max)
    var allowedRules: Int {
        return hasPremium ? Int.max : (maxDailyRules + (rewardedPacks * 5))
    }
    
    var body: some View {
        LocalizedView {
            ZStack {
                if achievementManager.showToast, let achievement = achievementManager.currentAchievement {
                    ToastView(achievement: achievement, isShowing: $achievementManager.showToast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                        .padding(.top, 50)
                }
                
                VStack {
                    TopMenuView(showSettings: $showSettings, showPushView: $showPushView)
                    
                    VStack(spacing: ThemeManager.layout.spacing.medium) {
                        // Header + share
                        ZStack {
                            Text("the_rule_for_today".appLocalized)
                                .font(ThemeManager.typography.headline)
                                .foregroundColor(ThemeManager.colors.lightText)
                            
                            HStack {
                                Spacer()
                                Button(action: { shareRule() }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(ThemeManager.colors.lightText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(ThemeManager.layout.spacing.medium)
                        .background(
                            RoundedRectangle(cornerRadius: ThemeManager.layout.cornerRadius.medium)
                                .fill(ThemeManager.colors.primary)
                                .shadow(color: ThemeManager.colors.cardShadow, radius: isLowEndDevice ? 2 : 5)
                        )
                        .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: ThemeManager.layout.cornerRadius.medium)
                                .fill(ThemeManager.colors.cardBackground)
                                .shadow(color: ThemeManager.colors.cardShadow, radius: isLowEndDevice ? 3 : 8)
                            
                            VStack {
                                Text(randomRule)
                                    .font(ThemeManager.typography.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(ThemeManager.colors.primaryText)
                                    .padding()
                                
                                Spacer()
                            }
                        }
                        .frame(width: ScreenMetrics.adaptiveWidth(85), height: ScreenMetrics.adaptiveHeight(33))
                        .overlay(
                            Group {
                                // 🟡 PREMIUM: ukryj reklamę, jeśli użytkownik ma Premium
                                if !hasPremium {
                                    AdBannerView(adUnitID: bannerAdUnitID)
                                        .frame(height: 50)
                                        .padding(8)
                                }
                            },
                            alignment: .bottomLeading
                        )
                        .padding(.horizontal)
                        
                        HStack {
                            MainActionButton(title: "draw".appLocalized, icon: "dice.fill") {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    refreshDailyStateIfNeeded()
                                    
                                    // 🟡 PREMIUM: brak alertu i limitu
                                    if !hasPremium && dailyRulesCount >= allowedRules {
                                        HapticManager.shared.notification(type: .warning)
                                        showAlert = true
                                        randomRule = lastDrawnRule
                                    } else {
                                        HapticManager.shared.impact(style: .medium)
                                        getRandomRule()
                                    }
                                }
                            }
                            
                            MainActionButton(title: "save".appLocalized, icon: "bookmark.fill") {
                                withAnimation(.spring()) {
                                    HapticManager.shared.impact(style: .medium)
                                    saveRule()
                                    showRulesList = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                    BottomNavigationMenu(savedRules: $savedRules)
                }
                
                if isLoading {
                    LoadingView()
                }
            }
            // 🟡 PREMIUM: alert „więcej zasad” nigdy się nie pokaże, bo showAlert ustawiamy tylko bez Premium
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("daily_limit".appLocalized),
                    message: Text("come_back_tomorrow".appLocalized),
                    primaryButton: .default(Text("bonus_rules_add".appLocalized), action: {
                        showRewardedAd()
                    }),
                    secondaryButton: .cancel(Text("OK"))
                )
            }
            .alert("success".appLocalized, isPresented: $showSaveAlert) {
                Button("ok".appLocalized, role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
            .onAppear {
                rebuildCategorizedRules()
                refreshDailyStateIfNeeded()
                loadSavedRules()
                loadUsedRulesIndices()
                loadLastDrawnRule()
                // 🟡 PREMIUM: nie ładuj rewarded ad na starcie, by przyspieszyć uruchamianie
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                rebuildCategorizedRules()
                loadLastDrawnRule()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppReset"))) { _ in
                savedRules = []
                usedRulesIndices = []
                dailyRulesCount = 0
                totalRulesDrawn = 0
                totalRulesSaved = 0
                randomRule = ""
                lastDrawnRule = ""
                loadSavedRules()
                loadUsedRulesIndices()
                loadLastDrawnRule()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refreshDailyStateIfNeeded()
            }
            .onChange(of: selectedCategoryKey) {
                loadUsedRulesIndices()
                loadLastDrawnRule()
            }
            .onChange(of: hasPremium, initial: false) { _, newValue in
                if newValue {
                    showAlert = false
                    rewardedPacks = 0
                } else {
                    loadRewardedAd()
                }
            }
        }
    }
    
    // MARK: - Rewarded Ad Logic
    func loadRewardedAd() {
        // 🟡 PREMIUM: nic nie rób, jeśli Premium
        guard !hasPremium else { return }
        
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request) { ad, error in
            if let error = error {
#if DEBUG
                print("❌ Nie udało się załadować rewarded ad: \(error.localizedDescription)")
#endif
                return
            }
            self.rewardedAd = ad
            rewardedAdDelegate.adDidDismiss = {
                self.loadRewardedAd()
            }
            rewardedAdDelegate.adDidFail = { error in
#if DEBUG
                print("❌ Rewarded ad failed: \(error.localizedDescription)")
#endif
            }
            self.rewardedAd?.fullScreenContentDelegate = rewardedAdDelegate
#if DEBUG
            print("✅ Rewarded ad załadowana")
#endif
        }
    }
    
    func showRewardedAd() {
        // 🟡 PREMIUM: nie pokazujemy rewarded ad
        guard !hasPremium else { return }
        
        // Lazy load: jeśli nie mamy reklamy, załaduj i spróbuj później
        guard let rewardedAd = rewardedAd else {
#if DEBUG
            print("ℹ️ Brak załadowanej reklamy – inicjuję ładowanie i przerwę pokaz.")
#endif
            loadRewardedAd()
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rewardedAd.present(from: rootViewController) {
#if DEBUG
                print("✅ Użytkownik obejrzał reklamę do końca – dodajemy +5 zasad")
#endif
                rewardedPacks += 1
#if DEBUG
                print("🎁 rewardedPacks zwiększony do \(rewardedPacks)")
#endif
                loadRewardedAd()
            }
        } else {
#if DEBUG
            print("❌ Brak okna do prezentacji – ponawiam ładowanie rewarded ad")
#endif
            loadRewardedAd()
        }
    }

    // MARK: - [KATEGORIE] Budowa i filtr listy
    private func getLocalizedRules() -> [String] {
        // 🔁 [ZMIANA] spójność z SettingsView – korzystamy z LanguageManager
        let code: String
        switch languageManager.currentLanguage {
        case .polish: code = "pl"
        case .spanish: code = "es"
        default: code = "en"
        }
        switch code {
        case "pl": return RulesListPL
        case "es": return RulesListES
        default:   return RulesList
        }
    }
    
    private func rebuildCategorizedRules() {
        let base = getLocalizedRules()
        // Upewnij się, że masz metodę build(from:) w VanlifeRulesFactory
        categorizedAllRules = VanlifeRulesFactory.build(from: base)
    }
    
    private var eligibleCategorized: [VanlifeRule] {
        guard selectedCategoryKey != "all",
              let cat = RuleCategory(rawValue: selectedCategoryKey) else {
            return categorizedAllRules
        }
        return categorizedAllRules.filter { $0.category == cat }
    }
    
    private var eligibleTexts: [String] {
        eligibleCategorized.map { $0.text }
    }
    
    // MARK: - Losowanie / zapis
    private func saveLastDrawnRule() {
        UserDefaults.standard.set(randomRule, forKey: "lastDrawnRule")
        lastDrawnRule = randomRule
    }
    
    private func loadLastDrawnRule() {
        if let lastRule = UserDefaults.standard.string(forKey: "lastDrawnRule") {
            randomRule = lastRule
            lastDrawnRule = lastRule
        } else {
            let currentRules = eligibleTexts
            let allIndices = Set(0..<currentRules.count)
            let usedIndicesSet = Set(usedRulesIndices)
            let availableIndices = allIndices.subtracting(usedIndicesSet)
            if availableIndices.isEmpty {
                randomRule = "all_rules_used".appLocalized
                return
            }
            if let randomIndex = availableIndices.randomElement() {
                randomRule = currentRules[randomIndex]
                lastDrawnRule = randomRule
                saveLastDrawnRule()
            }
        }
    }
    
    private func getRandomRule() {
        refreshDailyStateIfNeeded()
        
        let currentRules = eligibleTexts
        let allIndices = Set(0..<currentRules.count)
        let usedIndicesSet = Set(usedRulesIndices)
        let availableIndices = allIndices.subtracting(usedIndicesSet)
        
        if availableIndices.isEmpty {
            randomRule = "all_rules_used".appLocalized
            saveLastDrawnRule()
            return
        }
        
        // 🟡 PREMIUM: pomijamy limit
        if !hasPremium && dailyRulesCount >= allowedRules {
            showAlert = true
            randomRule = lastDrawnRule
            return
        }
        
        if let randomIndex = availableIndices.randomElement() {
            randomRule = currentRules[randomIndex]
            if !usedRulesIndices.contains(randomIndex) {
                usedRulesIndices.append(randomIndex)
                saveUsedRulesIndices()
                
                // premium nie zwiększa licznika, free – tak
                if !hasPremium {
                    dailyRulesCount += 1
                }
                
                saveLastDrawnRule()
                
                totalRulesDrawn += 1
                achievementManager.checkAchievements(
                    rulesDrawn: totalRulesDrawn,
                    rulesSaved: totalRulesSaved,
                    rulesShared: totalRulesShared,
                    locationsSaved: 0
                )
                
                // 🟡 PREMIUM: nie pokazuj timera/animacji dla reklam
                if !hasPremium {
                    withAnimation { shouldShowAd = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        withAnimation { shouldShowAd = false }
                    }
                }
            }
        }
    }

    // MARK: - Dzienny limit (rolling 24h)
    /// Reset stanu limitu, jeśli minęło 24h od lastRulesDate
    @discardableResult
    private func refreshDailyStateIfNeeded(now: Date = Date()) -> Bool {
        migrateLastRulesDateIfNeeded()
        let elapsed = now.timeIntervalSince1970 - lastRulesDate
        if elapsed >= 24 * 60 * 60 || lastRulesDate == 0 {
#if DEBUG
            print("🔁 Reset stanu (rolling 24h). elapsed=\(elapsed)")
#endif
            dailyRulesCount = 0
            usedRulesIndices = []
            lastRulesDate = now.timeIntervalSince1970
            saveUsedRulesIndices()
            UserDefaults.standard.removeObject(forKey: "lastDrawnRule")
            rewardedPacks = 0 // reset bonusów reklamowych co 24h
            return true
        } else {
#if DEBUG
            let remaining = Int(24*60*60 - elapsed)
            print("ℹ️ Brak resetu. Pozostało \(remaining)s do resetu.")
#endif
            return false
        }
    }

    /// Migracja ms→s, jeśli kiedyś zapisano w milisekundach
    private func migrateLastRulesDateIfNeeded() {
        // jeśli wartość wygląda na ms (większa niż ~01-01-2100 w sekundach)
        if lastRulesDate > 4102444800 { // 2100-01-01 w sekundach
            lastRulesDate = lastRulesDate / 1000.0
        }
    }

    /// Ile sekund zostało do resetu 24h
    private func secondsUntilReset(now: Date = Date()) -> Int {
        migrateLastRulesDateIfNeeded()
        let elapsed = now.timeIntervalSince1970 - lastRulesDate
        return max(0, Int(24*60*60 - elapsed))
    }

#if DEBUG
    /// Narzędzie do testów: cofnij znacznik lastRulesDate o X godzin
    private func debugBackdate(hours: Double) {
        lastRulesDate = Date().addingTimeInterval(-hours * 3600).timeIntervalSince1970
    }
#endif
    
    func shareRule() {
        guard let image = generateImage() else {
            print("Failed to generate image")
            return
        }
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // ✅ Achievement i licznik tylko po faktycznym udostępnieniu
        activityViewController.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                totalRulesShared &+= 1
                achievementManager.recordShareAction() // odblokuj 'first_share'
                achievementManager.checkAchievements(
                    rulesDrawn: totalRulesDrawn,
                    rulesSaved: totalRulesSaved,
                    rulesShared: totalRulesShared,
                    locationsSaved: 0
                )
            } else {
#if DEBUG
                print("ℹ️ Udostępnianie anulowane")
#endif
            }
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(activityViewController, animated: true)
        }
    }
    
    func generateImage() -> UIImage? {
        let maxWidth: CGFloat = 300
        let maxHeight: CGFloat = 200
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
        let attributedText = NSAttributedString(string: randomRule, attributes: textAttributes)
        let textRect = attributedText.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let imageSize = CGSize(
            width: max(textRect.width + 40, maxWidth),
            height: max(textRect.height + 40, maxHeight)
        )
        let image = UIGraphicsImageRenderer(size: imageSize).image { context in
            UIColor(ThemeManager.colors.secondary).setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            attributedText.draw(in: CGRect(
                x: 20,
                y: 20,
                width: imageSize.width - 40,
                height: imageSize.height - 40
            ))
            let watermarkText = "travel_rules".appLocalized
            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor(ThemeManager.colors.primary)
            ]
            let watermarkSize = watermarkText.size(withAttributes: watermarkAttributes)
            let watermarkRect = CGRect(
                x: imageSize.width - watermarkSize.width - 10,
                y: imageSize.height - watermarkSize.height - 10,
                width: watermarkSize.width,
                height: watermarkSize.height
            )
            watermarkText.draw(in: watermarkRect, withAttributes: watermarkAttributes)
        }
        return image
    }
    
    // MARK: - Zapis / odczyt
    private func stripLeadingNumber(_ text: String) -> String {
        if let dotIdx = text.firstIndex(of: ".") {
            let afterDot = text.index(after: dotIdx)
            return text[afterDot...].trimmingCharacters(in: .whitespaces)
        }
        return text
    }
    
    private func findRuleIndex(_ rule: String) -> Int? {
        if let idx = RulesList.firstIndex(of: rule) { return idx }
        if let idx = RulesListPL.firstIndex(of: rule) { return idx }
        if let idx = RulesListES.firstIndex(of: rule) { return idx }

        func indexByStrippedMatch(in list: [String]) -> Int? {
            for (i, raw) in list.enumerated() {
                if stripLeadingNumber(raw) == rule { return i }
            }
            return nil
        }
        if let i = indexByStrippedMatch(in: RulesList) { return i }
        if let i = indexByStrippedMatch(in: RulesListPL) { return i }
        if let i = indexByStrippedMatch(in: RulesListES) { return i }

        if let item = categorizedAllRules.first(where: { $0.text == rule }) {
            return max(0, item.id - 1)
        }
        return nil
    }
    
    private func saveRule() {
        if let index = findRuleIndex(randomRule) {
            if !savedRules.contains(index) {
                savedRules.append(index)
                saveRules()
                getRandomRule()
                totalRulesSaved += 1
                achievementManager.checkAchievements(
                    rulesDrawn: totalRulesDrawn,
                    rulesSaved: totalRulesSaved,
                    rulesShared: totalRulesShared,
                    locationsSaved: 0
                )
                saveAlertMessage = "rule_saved".appLocalized
                showSaveAlert = true
            } else {
                saveAlertMessage = "rule_exists".appLocalized
                showSaveAlert = true
            }
        } else {
            saveAlertMessage = "rule_exists".appLocalized
            showSaveAlert = true
        }
    }
    
    private func saveUsedRulesIndices() {
        let indices = usedRulesIndices
        Task.detached(priority: .utility) {
            if let encoded = try? JSONEncoder().encode(indices) {
                await MainActor.run {
                    UserDefaults.standard.set(encoded, forKey: usedIndicesStorageKey)
                }
            }
        }
    }
    
    private func loadUsedRulesIndices() {
        Task(priority: .utility) {
            if let data = UserDefaults.standard.data(forKey: usedIndicesStorageKey),
               let decoded = try? JSONDecoder().decode([Int].self, from: data) {
                self.usedRulesIndices = decoded
                return
            }
            if let data = UserDefaults.standard.data(forKey: "usedRulesIndices"),
               let decoded = try? JSONDecoder().decode([Int].self, from: data) {
                self.usedRulesIndices = decoded
                if let encoded = try? JSONEncoder().encode(decoded) {
                    UserDefaults.standard.set(encoded, forKey: usedIndicesStorageKey)
                }
                return
            }
            self.usedRulesIndices = []
        }
    }
    
    private func saveRules() {
        let rules = savedRules
        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(rules) {
                await MainActor.run {
                    UserDefaults.standard.set(data, forKey: "savedRules")
                }
            } else {
                await MainActor.run { self.showAlert = true }
            }
        }
    }
    
    private func loadSavedRules() {
        Task.detached(priority: .utility) {
            if let data = UserDefaults.standard.data(forKey: "savedRules"),
               let decoded = try? JSONDecoder().decode([Int].self, from: data) {
                await MainActor.run { self.savedRules = decoded }
            }
        }
    }
}

extension NextView {
    
}

// MARK: - Navigation Components

struct BottomNavigationMenu: View {
    @Binding var savedRules: [Int]
    
    var body: some View {
        HStack {
            NavigationButton(destination: MyChecklistView(), icon: "checkmark.circle")
            NavigationButton(destination: GPSView(), icon: "signpost.right.and.left")
            NavigationButton(destination: RulesListView(), icon: "list.star")
            NavigationButton(destination: AiTravelAssistantView(), icon: "shareplay")
        }
        .padding(.horizontal)
    }
}

struct NavigationButton<Destination: View>: View {
    let destination: Destination
    let icon: String
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:
            return ThemeColors.classicTheme
        case .mountain:
            return ThemeColors.mountainTheme
        case .beach:
            return ThemeColors.beachTheme
        case .desert:
            return ThemeColors.desertTheme
        case .forest:
            return ThemeColors.forestTheme
        case .autumn:
            return ThemeColors.autumnTheme
        case .winter:
            return ThemeColors.winterTheme
        case .summer:
            return ThemeColors.summerTheme
        case .spring:
            return ThemeColors.springTheme
        }
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            RoundedRectangle(cornerRadius: ThemeManager.layout.cornerRadius.medium)
                .padding(.all, 5)
                .foregroundColor(themeColors.secondary)
                .frame(width: ScreenMetrics.adaptiveWidth(20), height: ScreenMetrics.adaptiveWidth(20))
                .shadow(color: themeColors.cardShadow, radius: UIScreen.main.nativeBounds.height <= 1334 ? 2 : 5)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(themeColors.primaryText)
                        .font(.system(size: 40))
                )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}
    
