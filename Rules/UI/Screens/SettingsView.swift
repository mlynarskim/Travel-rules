import SwiftUI
import Foundation
import AVFoundation
import UIKit
import StoreKit

// MARK: - Background music (bez zmian)
var audioPlayer: AVAudioPlayer?

func playBackgroundMusic() {
    guard let musicURL = Bundle.main.url(forResource: "ambient-wave-48-tribute-17243", withExtension: "mp3") else {
        return
    }
    do {
        audioPlayer = try AVAudioPlayer(contentsOf: musicURL)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.play()
    } catch {
        print("Failed to play background music.")
    }
}

func stopBackgroundMusic() {
    audioPlayer?.stop()
    audioPlayer?.currentTime = 0
}

// MARK: - [PAYWALL] StoreKit 2 Manager (subskrypcje: monthly/yearly)
@MainActor
final class PurchaseManager: ObservableObject {
    private let premiumProductID = "com.mlynarski.travelrules.premium.monthly"
    private let premiumYearlyProductID = "com.mlynarski.travelrules.premium.yearly"
    
    @Published var premiumProduct: Product?
    @Published var premiumMonthlyProduct: Product?
    @Published var premiumYearlyProduct: Product?
    
    @Published var isPurchasing = false
    @Published var lastError: String?
    
    // aktywna subskrypcja (do UI)
    @Published var activeProductID: String?
    var isYearlyActive: Bool? {
        guard let id = activeProductID else { return nil }
        return id == premiumYearlyProductID
    }
    
    private var transactionListenerTask: Task<Void, Never>?
    deinit { transactionListenerTask?.cancel() }
    
    func loadProducts() async {
        do {
            let ids = [premiumProductID, premiumYearlyProductID]
            let products = try await Product.products(for: ids)
            for p in products {
                if p.id == premiumProductID { premiumMonthlyProduct = p }
                if p.id == premiumYearlyProductID { premiumYearlyProduct = p }
            }
            premiumProduct = premiumMonthlyProduct ?? premiumYearlyProduct
            if premiumMonthlyProduct == nil && premiumYearlyProduct == nil {
                lastError = "product_unavailable".appLocalized
            }
            print("📦 Products loaded:",
                  premiumMonthlyProduct?.id ?? "nil",
                  premiumYearlyProduct?.id ?? "nil")
        } catch {
            lastError = error.localizedDescription
            print("❌ [StoreKit] products error: \(error.localizedDescription)")
        }
    }
    
    func updatePurchased(hasPremiumBinding: Binding<Bool>) async {
        var hasPremium = false
        activeProductID = nil
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               (transaction.productID == premiumProductID || transaction.productID == premiumYearlyProductID) {
                hasPremium = true
                activeProductID = transaction.productID
            }
        }
        hasPremiumBinding.wrappedValue = hasPremium
        print("🔐 Premium status updated ->", hasPremium, " | active:", activeProductID ?? "nil")
    }
    
    func purchase(product: Product?, hasPremiumBinding: Binding<Bool>) async {
        guard let product else {
            lastError = "product_unavailable".appLocalized
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .unverified(_, let err):
                    lastError = err.localizedDescription
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchased(hasPremiumBinding: hasPremiumBinding)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
            print("❌ [StoreKit] purchase error: \(error.localizedDescription)")
        }
    }
    
    func purchase(hasPremiumBinding: Binding<Bool>) async {
        await purchase(product: premiumProduct, hasPremiumBinding: hasPremiumBinding)
    }
    
    func restore(hasPremiumBinding: Binding<Bool>) async {
        do {
            try await AppStore.sync()
            await updatePurchased(hasPremiumBinding: hasPremiumBinding)
        } catch {
            lastError = error.localizedDescription
            print("❌ [StoreKit] restore error: \(error.localizedDescription)")
        }
    }
    
    func listenForTransactions(hasPremiumBinding: Binding<Bool>) {
        transactionListenerTask?.cancel()
        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                guard case .verified(let transaction) = result else { continue }
                await self.updatePurchased(hasPremiumBinding: hasPremiumBinding)
                await transaction.finish()
            }
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @Binding var showSettings: Bool
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("isMusicEnabled") var isMusicEnabled = true
    @AppStorage("reduceEffects") private var reduceEffects: Bool = false
    @AppStorage("reduceTransparency") private var reduceTransparency: Bool = false
    @State private var showThemeSelector = false
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("selectedCategoryKey") private var selectedCategoryKey: String = "all"
    @AppStorage("hasPremium") private var hasPremium: Bool = false
    @StateObject private var purchaseManager = PurchaseManager()
    @State private var showPaywallSheet = false
    @State private var tempSelectedCategoryKey: String = "all"
    @State private var selectedPlanIsYearly: Bool = false
    @State private var langRefreshToken: Int = 0
    @State private var showRedeemNotice: Bool = false
    @State private var redeemNoticeText: String = ""
    @State private var showRedeemOptions: Bool = false
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:  return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach:    return ThemeColors.beachTheme
        case .desert:   return ThemeColors.desertTheme
        case .forest:   return ThemeColors.forestTheme
        case .autumn:   return ThemeColors.autumnTheme
        case .winter:   return ThemeColors.winterTheme
        case .spring:   return ThemeColors.springTheme
        case .summer:   return ThemeColors.summerTheme
        }
    }
    
    private var isSmallDevice: Bool { UIScreen.main.bounds.height <= 667 } // iPhone 7/8/SE
    
    private var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String, !build.isEmpty {
            return "\(version) (\(build))"
        }
        return version
    }

    // Dodatkowa kompensacja dla urządzeń bez notcha (np. iPhone SE/8)
    private var topSafeInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = scene?.windows.first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 0
    }
    private var headerExtraTopPadding: CGFloat {
        // na SE/8 topSafeInset ≈ 20; na urządzeniach z notchem ≈ 44+
        return topSafeInset < 30 ? 24 : 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Używa zasobów z Asset Catalog: jasny -> "theme-*-preview", ciemny -> "*-bg-dark"
                BackgroundArtwork(
                    selectedTheme: selectedTheme,
                    isDarkMode: isDarkMode,
                    fallbackColor: themeColors.secondary,
                    reduceTransparency: reduceTransparency,
                    isSmallDevice: isSmallDevice
                )
                
                ScrollView {
                    VStack(spacing: isSmallDevice ? 10 : 16) {
                        VStack(spacing: isSmallDevice ? 16 : 20) {
                            AppearanceCard(
                                themeColors: themeColors,
                                isDarkMode: $isDarkMode,
                                isMusicEnabled: $isMusicEnabled,
                                reduceEffects: $reduceEffects,
                                reduceTransparency: $reduceTransparency
                            )
                            
                            ThemeLangCard(
                                themeColors: themeColors,
                                showThemeSelector: $showThemeSelector,
                                languageManager: languageManager
                            )
                            
                            CategoryCard(
                                themeColors: themeColors,
                                hasPremium: hasPremium,
                                tempSelectedCategoryKey: $tempSelectedCategoryKey,
                                selectedCategoryKey: $selectedCategoryKey,
                                showPaywall: { showPaywallSheet = true },
                                isSmallDevice: isSmallDevice
                            )
                            
                            PremiumCard(
                                themeColors: themeColors,
                                isSmallDevice: isSmallDevice,
                                hasPremium: hasPremium,
                                activePlanIsYearly: purchaseManager.isYearlyActive,
                                selectedPlanIsYearly: $selectedPlanIsYearly,
                                monthlyProduct: purchaseManager.premiumMonthlyProduct,
                                yearlyProduct: purchaseManager.premiumYearlyProduct,
                                defaultProduct: purchaseManager.premiumProduct,
                                isPurchasing: purchaseManager.isPurchasing,
                                buyTapped: {
                                    Task {
                                        let product = selectedPlanIsYearly
                                        ? (purchaseManager.premiumYearlyProduct ?? purchaseManager.premiumProduct)
                                        : (purchaseManager.premiumMonthlyProduct ?? purchaseManager.premiumProduct)
                                        await purchaseManager.purchase(product: product, hasPremiumBinding: $hasPremium)
                                    }
                                },
                                restoreTapped: {
                                    Task { await purchaseManager.restore(hasPremiumBinding: $hasPremium) }
                                },
                                manageTapped: {
                                    openManageSubscriptions()
                                },
                                redeemTapped: {
                                    showRedeemOptions = true
                                },
                                lastError: purchaseManager.lastError
                            )
                            
                            Button(action: { resetApplication() }) {
                                Text("reset_all_settings".appLocalized)
                                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: isSmallDevice ? 44 : 50)
                                    .background(Color(hex: "#fc2c03"))
                                    .cornerRadius(12)
                                    .shadow(color: themeColors.cardShadow, radius: 4)
                            }
                            .padding(.horizontal)
                            .buttonStyle(.plain)
                            
                            ActionsCard(themeColors: themeColors, shareApp: shareApp, rateApp: rateApp, sendFeedback: sendFeedback)
                            
                            LegalLinksCard(
                                themeColors: themeColors,
                                isSmallDevice: isSmallDevice,
                                privacyURL: URL(string: "https://www.travelrules.eu/polityka-prywatnosci.html")!,
                                termsURL: URL(string: "https://www.travelrules.eu/warunki-korzystania.html")!
                            )
                            
                            VersionFooter(
                                themeColors: themeColors,
                                versionText: "version".appLocalized + " " + appVersionString
                            )
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, isSmallDevice ? 12 : 16)
                        .padding(.top, isSmallDevice ? 64 : 76)
                    }
                }
                .id(langRefreshToken)
                .scrollIndicators(.hidden)
                
                if purchaseManager.isPurchasing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.3)
                    }
                    .transition(.opacity)
                }
            }
            .safeAreaInset(edge: .top) {
                HeaderBar(themeColors: themeColors, isSmallDevice: isSmallDevice) {
                    showSettings = false
                }
                .padding(.horizontal, isSmallDevice ? 12 : 16)
                .padding(.top, headerExtraTopPadding)
            }
        }
        .sheet(isPresented: $showThemeSelector) { ThemeSelectionView() }
        .task {
            tempSelectedCategoryKey = selectedCategoryKey
            await purchaseManager.loadProducts()
            await purchaseManager.updatePurchased(hasPremiumBinding: $hasPremium)
            purchaseManager.listenForTransactions(hasPremiumBinding: $hasPremium)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallSheet(
                themeColors: themeColors,
                product: selectedPlanIsYearly ? (purchaseManager.premiumYearlyProduct ?? purchaseManager.premiumProduct)
                                              : (purchaseManager.premiumMonthlyProduct ?? purchaseManager.premiumProduct),
                isPurchasing: purchaseManager.isPurchasing,
                buyAction: {
                    Task {
                        let product = selectedPlanIsYearly
                        ? (purchaseManager.premiumYearlyProduct ?? purchaseManager.premiumProduct)
                        : (purchaseManager.premiumMonthlyProduct ?? purchaseManager.premiumProduct)
                        await purchaseManager.purchase(product: product, hasPremiumBinding: $hasPremium)
                        showPaywallSheet = false
                    }
                },
                restoreAction: {
                    Task {
                        await purchaseManager.restore(hasPremiumBinding: $hasPremium)
                        showPaywallSheet = false
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            langRefreshToken &+= 1
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await purchaseManager.updatePurchased(hasPremiumBinding: $hasPremium) }
        }
        .alert("redeem_title".appLocalized, isPresented: $showRedeemNotice) {
            Button("ok".appLocalized, role: .cancel) { }
        } message: {
            Text(redeemNoticeText)
        }
        .confirmationDialog("redeem_title".appLocalized,
                            isPresented: $showRedeemOptions,
                            titleVisibility: .visible) {
            Button("redeem_in_store".appLocalized) {
                openOfferCodeRedeemPage()
            }
            Button("cancel".appLocalized, role: .cancel) { }
        }
    }
    
    // MARK: - Helpers
    private func openOfferCodeRedeemPage() {
        let appStoreURL = URL(string: "itms-apps://apps.apple.com/redeem")
        let webURL = URL(string: "https://apps.apple.com/redeem")

        if let url = appStoreURL {
            UIApplication.shared.open(url, options: [:]) { success in
                if success { return }
                if let web = webURL {
                    UIApplication.shared.open(web)
                }
            }
            return
        }

        if let web = webURL {
            UIApplication.shared.open(web)
        }
    }

    private func currentCategoryTitle(for key: String) -> String {
        if key == "all" { return "category.all.title".appLocalized }
        if let cat = RuleCategory.allCases.first(where: { $0.rawValue == key }) {
            return cat.rawValue.appLocalized
        }
        return "category.all.title".appLocalized
    }
    
    private func shareApp() {
        let appLink = "https://apps.apple.com/pl/app/travel-rules/id6451070215?l=pl"
        let shareText = "Check out Travel-Rules!"
        let activityController = UIActivityViewController(
            activityItems: [shareText, appLink],
            applicationActivities: nil
        )
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
               let topController = keyWindow.rootViewController?.topmostViewController() {
                
                if let popover = activityController.popoverPresentationController {
                    popover.sourceView = topController.view
                    popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topController.present(activityController, animated: true, completion: nil)
            } else {
                print("Nie udało się znaleźć aktywnego widoku kontrolera.")
            }
        }
    }
    
    private func rateApp() {
        if let url = URL(string: "https://apps.apple.com/app/id6451070215?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendFeedback() {
        if let url = URL(string: "mailto:mlynarski.mateusz@gmail.com?subject=Feedback") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func openManageSubscriptions() {
        if #available(iOS 15.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) {
                Task {
                    do {
                        try await AppStore.showManageSubscriptions(in: scene)
                    } catch {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            await UIApplication.shared.open(url)
                        }
                    }
                }
            } else if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        } else if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetApplication() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController?.topmostViewController() else { return }
        
        let confirmReset = UIAlertController(
            title: "reset_title".appLocalized,
            message: "reset_message".appLocalized,
            preferredStyle: .alert
        )
        
        confirmReset.addAction(UIAlertAction(
            title: "reset_button".appLocalized,
            style: .destructive,
            handler: { _ in
                UserDefaults.standard.removeObject(forKey: "rules")
                UserDefaults.standard.removeObject(forKey: "savedRules")
                UserDefaults.standard.removeObject(forKey: "usedRulesIndices")
                UserDefaults.standard.removeObject(forKey: "lastDrawnRule")
                UserDefaults.standard.removeObject(forKey: "lastRulesDate")
                UserDefaults.standard.removeObject(forKey: "dailyRulesCount")
                UserDefaults.standard.removeObject(forKey: "totalRulesDrawn")
                UserDefaults.standard.removeObject(forKey: "totalRulesSaved")
                // Zresetuj osiągnięcia – usuń wpis, manager wczyta domyślne
                UserDefaults.standard.removeObject(forKey: "achievements")
                UserDefaults.standard.removeObject(forKey: "savedLocations")
                UserDefaults.standard.removeObject(forKey: "checklistItems")
                
                // Usuń ewentualne pliki z zapisanymi danymi (lokalizacje / checklisty) w Documents
                do {
                    let fm = FileManager.default
                    if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let candidates = [
                            "savedLocations.json",
                            "locations.json",
                            "locationData.json",
                            "SavedLocations.json",
                            "checklistItems.json",
                            "Checklist.json",
                            "my_checklist.json"
                        ]
                        for name in candidates {
                            let url = docs.appendingPathComponent(name)
                            if fm.fileExists(atPath: url.path) {
                                try? fm.removeItem(at: url)
                            }
                        }
                        // Dodatkowo usuń dowolny plik zawierający „location” lub „checklist” w nazwie
                        if let urls = try? fm.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil) {
                            for url in urls {
                                let lower = url.lastPathComponent.lowercased()
                                if lower.contains("location") || lower.contains("checklist") {
                                    try? fm.removeItem(at: url)
                                }
                            }
                        }
                    }
                }
                
                // [PAYWALL/KATEGORIE] Reset
                UserDefaults.standard.set("all", forKey: "selectedCategoryKey")
                UserDefaults.standard.set(false, forKey: "hasPremium")
                
                UserDefaults.standard.set(false, forKey: "isDarkMode")
                UserDefaults.standard.set(ThemeStyle.classic.rawValue, forKey: "selectedTheme")
                UserDefaults.standard.set(true, forKey: "isMusicEnabled")
                UserDefaults.standard.set("en", forKey: "selectedLanguage")
                
                UserDefaults.standard.synchronize()
                
                self.showSettings = false
                
                // Odśwież aplikację bez potrzeby ręcznego restartu
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: ContentView())
                    window.makeKeyAndVisible()
                }
            }))
        
        confirmReset.addAction(UIAlertAction(title: "cancel".appLocalized, style: .cancel, handler: nil))
        rootViewController.present(confirmReset, animated: true)
    }
}

// MARK: - Pod-widoki

private struct HeaderBar: View {
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let onClose: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Text("settings".appLocalized)
                .font(.system(size: isSmallDevice ? 24 : 28, weight: .bold))
                .foregroundColor(themeColors.primaryText)
                .padding(.vertical, isSmallDevice ? 8 : 12)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: isSmallDevice ? 20 : 24))
                    .foregroundColor(themeColors.primaryText)
                    .padding()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, isSmallDevice ? 8 : 12)
        .background(Color.clear)
    }
}

private struct AppearanceCard: View {
    let themeColors: ThemeColors
    @Binding var isDarkMode: Bool
    @Binding var isMusicEnabled: Bool
    @Binding var reduceEffects: Bool
    @Binding var reduceTransparency: Bool
    
    var body: some View {
        SettingsCard(themeColors: themeColors) {
            Toggle("dark_mode".appLocalized, isOn: $isDarkMode)
                .foregroundColor(themeColors.primaryText)
            Toggle("music".appLocalized, isOn: $isMusicEnabled)
                .foregroundColor(themeColors.primaryText)
                .onChange(of: isMusicEnabled) { _, newValue in
                    newValue ? playBackgroundMusic() : stopBackgroundMusic()
                }
            /// Dodatkowe przełączniki aplikacji – działają *wspólnie* z ustawieniami systemowymi (Reduce Motion/Transparency)
            Toggle("accessibility_reduce_effects".appLocalized, isOn: $reduceEffects)
                .foregroundColor(themeColors.primaryText)
                .onChange(of: reduceEffects) { _, _ in
                    NotificationCenter.default.post(name: NSNotification.Name("AccessibilityPrefsChanged"), object: nil)
                }
            Toggle("accessibility_reduce_transparency".appLocalized, isOn: $reduceTransparency)
                .foregroundColor(themeColors.primaryText)
                .onChange(of: reduceTransparency) { _, _ in
                    NotificationCenter.default.post(name: NSNotification.Name("AccessibilityPrefsChanged"), object: nil)
                }
        }
    }
}

private struct ThemeLangCard: View {
    let themeColors: ThemeColors
    @Binding var showThemeSelector: Bool
    let languageManager: LanguageManager
    
    var body: some View {
        SettingsCard(themeColors: themeColors) {
            Button(action: { showThemeSelector = true }) {
                HStack {
                    Text("themes".appLocalized).foregroundColor(themeColors.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(themeColors.secondaryText)
                }
            }
            .buttonStyle(.plain)
            Divider().background(themeColors.secondaryText)
            HStack {
                Text("language".appLocalized).foregroundColor(themeColors.primaryText)
                Spacer()
                Picker("", selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { language in
                        languageManager.currentLanguage = language
                        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
                    })
                ) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

private struct CategoryCard: View {
    let themeColors: ThemeColors
    let hasPremium: Bool
    @Binding var tempSelectedCategoryKey: String
    @Binding var selectedCategoryKey: String
    let showPaywall: () -> Void
    let isSmallDevice: Bool
    
    var body: some View {
        SettingsCard(themeColors: themeColors) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("category.settings.title".appLocalized)
                        .font(.system(size: isSmallDevice ? 18 : 20, weight: .semibold))
                        .foregroundColor(themeColors.primaryText)
                    Spacer()
                    Text(hasPremium ? "premium_active".appLocalized : "premium_locked".appLocalized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(hasPremium ? .green : .orange)
                }
                
                HStack {
                    Text("category.settings.choose".appLocalized)
                        .foregroundColor(themeColors.primaryText)
                    Spacer()
                    
                    let label = Text(currentCategoryTitle(for: tempSelectedCategoryKey))
                        .foregroundColor(themeColors.primary)
                    
                    Picker(selection: $tempSelectedCategoryKey) {
                        Text("category.all.title".appLocalized).tag("all")
                        ForEach(RuleCategory.allCases) { cat in
                            Text(cat.rawValue.appLocalized).tag(cat.rawValue)
                        }
                    } label: { label }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: tempSelectedCategoryKey) { _, newKey in
                        if newKey != "all" && !hasPremium {
                            tempSelectedCategoryKey = selectedCategoryKey
                            showPaywall()
                        } else {
                            selectedCategoryKey = newKey
                            NotificationCenter.default.post(name: NSNotification.Name("CategoryChanged"), object: nil)
                        }
                    }
                }
            }
        }
    }
    
    private func currentCategoryTitle(for key: String) -> String {
        if key == "all" { return "category.all.title".appLocalized }
        if let cat = RuleCategory.allCases.first(where: { $0.rawValue == key }) { return cat.rawValue.appLocalized }
        return "category.all.title".appLocalized
    }
}

private struct PremiumCard: View {
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let hasPremium: Bool
    let activePlanIsYearly: Bool?
    @Binding var selectedPlanIsYearly: Bool
    let monthlyProduct: Product?
    let yearlyProduct: Product?
    let defaultProduct: Product?
    let isPurchasing: Bool
    let buyTapped: () -> Void
    let restoreTapped: () -> Void
    let manageTapped: () -> Void
    let redeemTapped: () -> Void
    let lastError: String?
    
    // Lokalizacja ceny wg ustawień regionu urządzenia (np. PLN w PL)
    private func localizedPrice(_ product: Product?) -> String {
        guard let product else { return "—" }
        let style = product.priceFormatStyle.locale(Locale.current)
        return product.price.formatted(style)
    }

    var body: some View {
        SettingsCard(themeColors: themeColors) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeColors.primary)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(hasPremium ? "premium_active".appLocalized : "premium_title".appLocalized)
                            .font(.system(size: isSmallDevice ? 18 : 20, weight: .bold))
                            .foregroundColor(themeColors.primaryText)
                        
                        // Pigułka z typem planu, jeśli premium aktywne
                        if hasPremium, let isYearly = activePlanIsYearly {
                            Text(isYearly ? "yearly".appLocalized : "monthly".appLocalized)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeColors.primary.opacity(0.15))
                                .foregroundColor(themeColors.primary)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(hasPremium ? "premium_subtitle".appLocalized : "premium_subtitle".appLocalized)
                        .font(.system(size: 14))
                        .foregroundColor(themeColors.secondaryText)
                }
                Spacer()
            }
            
            if hasPremium {
                // 🔒 Użytkownik ma premium – tylko „Zarządzaj subskrypcją”
                Button(action: manageTapped) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.key.fill")
                        Text("premium_manage".appLocalized) // dodaj w Localizable
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(themeColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: isSmallDevice ? 44 : 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeColors.primary.opacity(0.8), lineWidth: 1.5)
                    )
                }
                .disabled(isPurchasing)
                .buttonStyle(.plain)
                
            } else {
                // 🛒 Brak premium – wybór planu + kup/restore
                HStack(spacing: 14) {
                    PlanPill(
                        title: "monthly".appLocalized,
                        subtitle: localizedPrice(monthlyProduct),
                        selected: !selectedPlanIsYearly,
                        themeColors: themeColors
                    ) { selectedPlanIsYearly = false }
                    
                    PlanPill(
                        title: "yearly".appLocalized,
                        subtitle: localizedPrice(yearlyProduct),
                        selected: selectedPlanIsYearly,
                        themeColors: themeColors
                    ) { selectedPlanIsYearly = true }
                }
                
                HStack {
                    Button(action: buyTapped) {
                        Text("premium_buy".appLocalized)
                            .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: isSmallDevice ? 44 : 50)
                            .background(themeColors.primary)
                            .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                    .buttonStyle(.plain)
                    
                    Button(action: restoreTapped) {
                        Text("premium_restore".appLocalized)
                            .font(.system(size: isSmallDevice ? 14 : 16, weight: .bold))
                            .foregroundColor(themeColors.primary)
                            .frame(height: isSmallDevice ? 44 : 50)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeColors.primary, lineWidth: 2)
                            )
                    }
                    .disabled(isPurchasing)
                    .buttonStyle(.plain)
                }
                Button(action: redeemTapped) {
                    Text("redeem_code".appLocalized) // ⚠️ dodaj klucz lokalizacji w Localizable.strings
                        .font(.system(size: 12, weight: .semibold))
                        .underline()
                        .foregroundColor(themeColors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
                .buttonStyle(.plain)
            }
            
            if let error = lastError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Reusable cards / rows

struct SettingsCard<Content: View>: View {
    let content: Content
    let themeColors: ThemeColors
    
    init(themeColors: ThemeColors, @ViewBuilder content: () -> Content) {
        self.themeColors = themeColors
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: themeColors.cardShadow, radius: 4)
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let action: String
    let iconColor: Color
    let themeColors: ThemeColors
    let callback: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
            Text(title)
                .foregroundColor(themeColors.primaryText)
            Spacer()
            Button(action: callback) {
                Text(action)
                    .foregroundColor(themeColors.primary)
            }
        }
    }
}

// ⛔️ NIEUŻYWANE (zostawione)
struct CategoryRow: View {
    let title: String
    let isSelected: Bool
    let locked: Bool
    let themeColors: ThemeColors
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(locked ? themeColors.secondaryText : themeColors.primaryText)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(themeColors.primary)
            }
            if locked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

struct PlanPill: View {
    let title: String
    let subtitle: String
    let selected: Bool
    let themeColors: ThemeColors
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selected ? .white : themeColors.primaryText)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? themeColors.primary : themeColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? themeColors.primary : themeColors.secondaryText.opacity(0.4), lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct ActionsCard: View {
    let themeColors: ThemeColors
    let shareApp: () -> Void
    let rateApp: () -> Void
    let sendFeedback: () -> Void
    
    var body: some View {
        SettingsCard(themeColors: themeColors) {
            SettingsButton(
                icon: "square.and.arrow.up",
                title: "share_app".appLocalized,
                action: "share".appLocalized,
                iconColor: themeColors.primary,
                themeColors: themeColors
            ) { shareApp() }
            
            Divider().background(themeColors.secondaryText)
            
            SettingsButton(
                icon: "star.fill",
                title: "rate_app".appLocalized,
                action: "rate".appLocalized,
                iconColor: .yellow,
                themeColors: themeColors
            ) { rateApp() }
            
            Divider().background(themeColors.secondaryText)
            
            SettingsButton(
                icon: "envelope.fill",
                title: "send_feedback".appLocalized,
                action: "send".appLocalized,
                iconColor: .red,
                themeColors: themeColors
            ) { sendFeedback() }
        }
    }
}

// MARK: - NOWE: LegalLinksCard (linki na dół ustawień)
private struct LegalLinksCard: View {
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let privacyURL: URL
    let termsURL: URL
    
    var body: some View {
        SettingsCard(themeColors: themeColors) {
            VStack(alignment: .leading, spacing: 10) {
                Text("legal.title".appLocalized) // dodaj np. „Informacje prawne”
                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .semibold))
                    .foregroundColor(themeColors.primaryText)
                
                Button {
                    UIApplication.shared.open(privacyURL)
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(themeColors.primary)
                        Text("privacy_policy".appLocalized) // „Polityka prywatności”
                            .foregroundColor(themeColors.primaryText)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(themeColors.secondaryText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider().background(themeColors.secondaryText.opacity(0.4))
                
                Button {
                    UIApplication.shared.open(termsURL)
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(themeColors.primary)
                        Text("terms_of_use".appLocalized) // „Warunki korzystania”
                            .foregroundColor(themeColors.primaryText)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(themeColors.secondaryText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - NOWE: stopka wersji
private struct VersionFooter: View {
    let themeColors: ThemeColors
    let versionText: String
    
    var body: some View {
        Text(versionText)
            .font(.system(size: 12))
            .foregroundColor(themeColors.secondaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .accessibilityLabel(versionText)
    }
}

// MARK: - Tła ilustracyjne dla motywów (jasny/ciemny)
private struct BackgroundArtwork: View {
    let selectedTheme: String
    let isDarkMode: Bool
    let fallbackColor: Color
    let reduceTransparency: Bool
    let isSmallDevice: Bool

    private var imageName: String? {
        // Mapowanie na zasoby istniejące w Asset Catalog:
        //  - jasny: "theme-*-preview"
        //  - ciemny: "*-bg-dark"
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        let light: (ThemeStyle) -> String = { theme in
            switch theme {
            case .classic:  return "theme-classic-preview"
            case .mountain: return "theme-mountain-preview"
            case .beach:    return "theme-beach-preview"
            case .desert:   return "theme-desert-preview"
            case .forest:   return "theme-forest-preview"
            case .autumn:   return "theme-autumn-preview"
            case .winter:   return "theme-winter-preview"
            case .spring:   return "theme-spring-preview"
            case .summer:   return "theme-summer-preview"
            }
        }
        let dark: (ThemeStyle) -> String = { theme in
            switch theme {
            case .classic:  return "classic-bg-dark"
            case .mountain: return "mountain-bg-dark"
            case .beach:    return "beach-bg-dark"
            case .desert:   return "desert-bg-dark"
            case .forest:   return "forest-bg-dark"
            case .autumn:   return "autumn-bg-dark"
            case .winter:   return "winter-bg-dark"
            case .spring:   return "spring-bg-dark"
            case .summer:   return "summer-bg-dark"
            }
        }
        return isDarkMode ? dark(theme) : light(theme)
    }

    var body: some View {
        ZStack {
            if let name = imageName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    // delikatne przyciemnienie/rozjaśnienie dla czytelności kart
                    .overlay(
                        LinearGradient(
                            colors: overlayColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                    // redukcja parallax/blur jeśli użytkownik ogranicza efekty
                    .overlay(
                        Group {
                            if reduceTransparency {
                                Color.black.opacity(isDarkMode ? 0.35 : 0.12)
                            } else {
                                Color.clear
                            }
                        }
                        .ignoresSafeArea()
                    )
            } else {
                fallbackColor.ignoresSafeArea()
            }
        }
    }

    private var overlayColors: [Color] {
        // Subtelna warstwa poprawiająca kontrast treści
        if isDarkMode {
            return [Color.black.opacity(0.25), Color.black.opacity(isSmallDevice ? 0.45 : 0.35)]
        } else {
            return [Color.white.opacity(0.06), Color.white.opacity(isSmallDevice ? 0.18 : 0.12)]
        }
    }
}

// MARK: - Paywall Sheet
struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    let themeColors: ThemeColors
    let product: Product?
    let isPurchasing: Bool
    let buyAction: () -> Void
    let restoreAction: () -> Void
    // ⬇️ Legal links (App Review 3.1.2)
    private let privacyURL = URL(string: "https://www.travelrules.eu/polityka-prywatnosci.html")!
    private let termsURL = URL(string: "https://www.travelrules.eu/warunki-korzystania.html")!

    // Krótki opis długości subskrypcji (lokalnie: używa istniejących kluczy "monthly"/"yearly")
    private func subscriptionLengthText(for product: Product?) -> String? {
        guard let period = product?.subscription?.subscriptionPeriod else { return nil }
        switch period.unit {
        case .month: return "monthly".appLocalized
        case .year:  return "yearly".appLocalized
        case .week:
            return "weekly".appLocalized // UWAGA: jeśli brak klucza, wyświetli się surowy tekst
        case .day:
            return "daily".appLocalized  // UWAGA: jeśli brak klucza, wyświetli się surowy tekst
        @unknown default:
            return nil
        }
    }
    
    // Cena sformatowana wg regionu urządzenia (np. PLN w PL)
    private func localizedPriceString(_ product: Product?) -> String? {
        guard let product else { return nil }
        let style = product.priceFormatStyle.locale(Locale.current)
        return product.price.formatted(style)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeColors.secondary.ignoresSafeArea()
                VStack(spacing: 16) {
                    Spacer(minLength: 8)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(themeColors.primary)
                    Text("premium_title".appLocalized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeColors.primaryText)
                    Text("premium_subtitle".appLocalized)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeColors.primaryText.opacity(0.8))
                        .padding(.horizontal)

                    if let price = localizedPriceString(product) {
                        Text("premium_price".appLocalized + " \(price)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeColors.primaryText)
                            .padding(.top, 6)
                    }
                    if let periodText = subscriptionLengthText(for: product) {
                        Text(periodText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(themeColors.secondaryText)
                    }

                    VStack(spacing: 12) {
                        Button(action: buyAction) {
                            Text("premium_buy".appLocalized)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(themeColors.primary)
                                .cornerRadius(12)
                        }
                        .disabled(isPurchasing)
                        .buttonStyle(.plain)

                        Button(action: restoreAction) {
                            Text("premium_restore".appLocalized)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(themeColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeColors.primary, lineWidth: 2)
                                )
                        }
                        .disabled(isPurchasing)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // ⬇️ Legal footer required by 3.1.2
                    HStack(spacing: 16) {
                        Button {
                            UIApplication.shared.open(privacyURL)
                        } label: {
                            Text("privacy_policy".appLocalized)
                                .font(.system(size: 12))
                                .underline()
                                .foregroundColor(themeColors.secondaryText)
                        }
                        .buttonStyle(.plain)
                        Button {
                            UIApplication.shared.open(termsURL)
                        } label: {
                            Text("terms_of_use".appLocalized)
                                .font(.system(size: 12))
                                .underline()
                                .foregroundColor(themeColors.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close".appLocalized) {
                        dismiss()
                    }
                    .foregroundColor(themeColors.primary)
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Helpers
extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presentedVC = presentedViewController {
            return presentedVC.topmostViewController()
        }
        if let navVC = self as? UINavigationController,
           let visibleVC = navVC.visibleViewController {
            return visibleVC.topmostViewController()
        }
        if let tabVC = self as? UITabBarController,
           let selectedVC = tabVC.selectedViewController {
            return selectedVC.topmostViewController()
        }
        return self
    }
}
