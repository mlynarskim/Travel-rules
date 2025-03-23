import SwiftUI
import ObjectiveC
import Foundation
import AVFoundation
import UIKit
import Darwin

// Prywatna struktura, która przechowuje klucze do asocjowanych obiektów.
private struct AssociatedKeys {
    static var bundleKey: Void?
}

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case polish = "pl"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .polish: return "Polski"
        case .spanish: return "Español"
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            updateLanguage(to: currentLanguage)
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
            refreshUI()
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? "system"
        currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        updateLanguage(to: currentLanguage)
    }
    
    func updateLanguage(to language: AppLanguage) {
        print("Updating language to: \(language.rawValue)")
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Używamy nowego API do pobrania kodu języka systemowego,
        // rozpakowując opcjonalną wartość lub używając domyślnego "en".
        let systemLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let languageCode = (language == .system) ? systemLanguageCode : language.rawValue
        
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("❌ Failed to get bundle for language: \(languageCode)")
            print("Available bundles: \(Bundle.main.localizations)")
            return
        }
        
        print("✅ Successfully loaded bundle for language: \(languageCode)")
        objc_setAssociatedObject(Bundle.main, &AssociatedKeys.bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func refreshUI() {
        objectWillChange.send()
    }
}

extension Bundle {
    var localizedBundle: Bundle {
        if let bundle = objc_getAssociatedObject(self, &AssociatedKeys.bundleKey) as? Bundle {
            return bundle
        }
        return self
    }
    
    func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return localizedBundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension String {
    var appLocalized: String {
        return NSLocalizedString(self, bundle: Bundle.main.localizedBundle, comment: "")
    }
}
