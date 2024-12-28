import SwiftUI
import ObjectiveC
import Foundation
import AVFoundation
import UIKit

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

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    static var bundleKey = 0  // Usunąłem private
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            updateLanguage(to: currentLanguage)
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
            refreshUI()
        }
    }
    
    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") ?? "system"
        currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        updateLanguage(to: currentLanguage)
    }
    
    func updateLanguage(to language: AppLanguage) {
        print("Updating language to: \(language.rawValue)")
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        let languageCode = language == .system ?
            Locale.current.languageCode ?? "en" :
            language.rawValue
        
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("❌ Failed to get bundle for language: \(languageCode)")
            print("Available bundles: \(Bundle.main.localizations)")
            return
        }
        
        print("✅ Successfully loaded bundle for language: \(languageCode)")
        objc_setAssociatedObject(Bundle.main, &LanguageManager.bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func refreshUI() {
        objectWillChange.send()
    }
}

extension Bundle {
    var localizedBundle: Bundle {
        if let bundle = objc_getAssociatedObject(self, &LanguageManager.bundleKey) as? Bundle {
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
