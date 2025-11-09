import SwiftUI
import UserNotifications

// MARK: - DocumentEntry
struct DocumentEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    let date: Date
    let documentKey: String
}

// MARK: - PushView
struct PushView: View {
    @Binding var showPushView: Bool
    
    @AppStorage("isNotificationEnabled") private var isNotificationEnabled = false
    @AppStorage("isMonthlyReminderEnabled") private var isMonthlyReminderEnabled = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    @StateObject private var languageManager = LanguageManager.shared
    @State private var viewRefresh = false
    
    // Pola do dodawania nowego dokumentu:
    @State private var selectedDate = Date()
    @State private var selectedDocumentKey = "dowod_osobisty"
    
    // Lista zapisanych dokumentów (z kluczami dokumentów):
    @State private var savedDocuments: [DocumentEntry] = [] {
        didSet {
            saveDocuments()
            scheduleDocumentNotifications()
        }
    }
    
    // Dostępne klucze dokumentów (bez .appLocalized)
    private let documentKeys = [
        "dowod_osobisty",
        "paszport",
        "ubezpieczenie_zdrowotne",
        "polisa_ubezpieczeniowa",
        "karty_platnicze",
        "wiza",
        "karta_ekuz",
        "ksiazeczka_szczepien",
        "prawo_jazdy",
        "miedzynarodowe_prawo_jazdy",
        "ubezpieczenie_oc"
    ]
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        case .autumn: return ThemeColors.autumnTheme
        case .spring: return ThemeColors.springTheme
        case .winter: return ThemeColors.winterTheme
        case .summer: return ThemeColors.summerTheme

        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeColors.secondary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Nagłówek
                    HStack {
                        Spacer()
                        Spacer()
                        Text("notification_settings".appLocalized)
                            .font(.title)
                            .foregroundColor(themeColors.primaryText)
                            .padding()
                        Spacer()
                        Button(action: { showPushView = false }) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 24))
                                .foregroundColor(themeColors.primaryText)
                                .padding()
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Główna sekcja: opisy + przełączniki + dodawanie dokumentów
                    VStack(spacing: 20) {
                        
                        // 1. Powiadomienia o zasadach
                        VStack(alignment: .leading, spacing: 5) {
                            Text("rule_notifications_title".appLocalized)
                                .foregroundColor(themeColors.primaryText)
                                .font(.subheadline)
                            
                            Toggle("enable_notifications".appLocalized, isOn: $isNotificationEnabled)
                                .onChange(of: isNotificationEnabled) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "isNotificationEnabled")
                                    if newValue {
                                        NotificationManager.instance.requestAuthorization { granted in
                                            DispatchQueue.main.async {
                                                self.isNotificationEnabled = granted
                                                if granted {
                                                    scheduleDailyRandomRuleNotification() // replaced old call to scheduleNotification()
                                                }
                                            }
                                        }
                                    } else {
                                        NotificationManager.instance.removeNotification(identifier: "daily_rule_notification")
                                    }
                                }
                                .padding(8)
                                .tint(themeColors.primary)
                                .foregroundColor(themeColors.primaryText)
                                .background(themeColors.cardBackground)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        
                        // 2. Powiadomienia o ważności dokumentów
                        VStack(alignment: .leading, spacing: 5) {
                            Text("document_validity_notifications_title".appLocalized)
                                .foregroundColor(themeColors.primaryText)
                                .font(.subheadline)
                            
                            Toggle("enable_monthly_reminder".appLocalized, isOn: $isMonthlyReminderEnabled)
                                .onChange(of: isMonthlyReminderEnabled) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "isMonthlyReminderEnabled")
                                    if newValue {
                                        scheduleDocumentNotifications()
                                    } else {
                                        NotificationManager.instance.removeNotification(identifier: "monthly_document_check")
                                    }
                                }
                                .padding(8)
                                .tint(themeColors.primary)
                                .foregroundColor(themeColors.primaryText)
                                .background(themeColors.cardBackground)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        
                        // 3. Data
                        DatePicker("choose_date".appLocalized, selection: $selectedDate, displayedComponents: [.date])
                            .datePickerStyle(.automatic)
                            .padding(8)
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                            .foregroundColor(themeColors.primaryText)
                            .padding(.horizontal, 16)
                        
                        // 4. Picker dokumentu (klucze) + Zapisz
                        HStack {
                            Picker("choose_document".appLocalized, selection: $selectedDocumentKey) {
                                ForEach(documentKeys, id: \.self) { key in
                                    Text(key.appLocalized)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(8)
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                            .foregroundColor(themeColors.primaryText)
                            
                            Button("save_button".appLocalized) {
                                // Sprawdzamy duplikat (porównujemy klucz)
                                let isDuplicate = savedDocuments.contains { doc in
                                    doc.documentKey == selectedDocumentKey &&
                                    Calendar.current.isDate(doc.date, inSameDayAs: selectedDate)
                                }
                                guard !isDuplicate else {
                                    print("duplicate_document_message".appLocalized)
                                    return
                                }
                                
                                let newEntry = DocumentEntry(date: selectedDate, documentKey: selectedDocumentKey)
                                savedDocuments.append(newEntry)
                            }
                            .padding()
                            .background(themeColors.primary)
                            .foregroundColor(themeColors.secondary)
                            .cornerRadius(10)
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 20)
                    }
                    
                    // 5. Lista dokumentów
                    List {
                        ForEach(savedDocuments) { entry in
                            HStack {
                                Text("\(entry.documentKey.appLocalized) - \(entry.date, formatter: dateFormatter)")
                                    .foregroundColor(themeColors.primaryText)
                                    .padding(.leading, 10)

                                Spacer()

                                // Przycisk usuwania
                                Button(action: {
                                    deleteDocument(entry)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding(8)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeColors.primary, lineWidth: 1)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3))
                        }
                    }
                    .padding()
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    
                    Spacer()
                }
            }
            .onAppear {
                loadDocuments()
                scheduleDocumentNotifications()
            }
            // Odświeżenie widoku po zmianie języka
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                viewRefresh.toggle()
            }
            .id(viewRefresh)
        }
    }
    
    // MARK: - Formatter daty
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    // MARK: - Zapis i odczyt dokumentów
    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(savedDocuments) {
            UserDefaults.standard.set(encoded, forKey: "savedDocuments")
        }
    }
    private func deleteDocument(_ entry: DocumentEntry) {
        withAnimation {
            savedDocuments.removeAll { $0.id == entry.id }
            NotificationManager.instance.removeNotification(identifier: "monthly_document_check")
        }
    }

    private func loadDocuments() {
        if let savedData = UserDefaults.standard.data(forKey: "savedDocuments"),
           let decoded = try? JSONDecoder().decode([DocumentEntry].self, from: savedData) {
            self.savedDocuments = decoded
        }
    }
    
    // MARK: - Powiadomienia
    private func scheduleDocumentNotifications() {
        guard isMonthlyReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "monthly_notification_title".appLocalized
        
        let docLines = savedDocuments.map { entry in
            "\(entry.documentKey.appLocalized) - \(dateFormatter.string(from: entry.date))"
        }.joined(separator: "\n")
        
        content.body = docLines.isEmpty
            ? String(localized: "no_documents_message")
            : docLines
        
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 12
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly_document_check",
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("monthly_notification_error".appLocalized, error)
            }
        }
    }
    
    // New helper to schedule daily random rule notification at 10:25
    private func scheduleDailyRandomRuleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "daily_rule_notification_title".appLocalized
        
        content.body = pickRandomLocalizedRule()
        
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 14
        dateComponents.minute = 00
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "daily_rule_notification",
                                            content: content,
                                            trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_rule_notification"])
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("daily_rule_notification_error".appLocalized, error)
            }
        }
        // Diagnostic dump of pending notification requests
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            let ids = reqs.map { $0.identifier }
            print("[DEBUG] Pending notifications count: \(reqs.count) | ids: \(ids)")
        }
    }
    
    // Helper to pick a random localized rule from in-memory arrays instead of bundled JSON
    private func pickRandomLocalizedRule() -> String {
        let code = currentLanguageCode()
        switch code {
        case "pl":
            if !RulesListPL.isEmpty {
                return RulesListPL.randomElement() ?? String(localized: "random_rule_fallback")
            }
        case "es":
            if !RulesListES.isEmpty {
                return RulesListES.randomElement() ?? String(localized: "random_rule_fallback")
            }
        case "en":
            if !RulesList.isEmpty {
                return RulesList.randomElement() ?? String(localized: "random_rule_fallback")
            }
        default:
            break
        }
        // Robust fallback chain
        if !RulesList.isEmpty {
            return RulesList.randomElement() ?? String(localized: "random_rule_fallback")
        }
        if !RulesListPL.isEmpty {
            return RulesListPL.randomElement() ?? String(localized: "random_rule_fallback")
        }
        if !RulesListES.isEmpty {
            return RulesListES.randomElement() ?? String(localized: "random_rule_fallback")
        }
        return String(localized: "random_rule_fallback")
    }
    
    // Helper to get current language code, normalized to primary subtag (e.g., "en-US" -> "en")
    private func currentLanguageCode() -> String {
        if let selectedCode = UserDefaults.standard.string(forKey: "selectedLanguageCode") {
            return selectedCode.components(separatedBy: CharacterSet(charactersIn: "-_")).first ?? selectedCode // normalize
        }
        let sysCode = Locale.current.language.languageCode?.identifier ?? "pl"
        return sysCode.components(separatedBy: CharacterSet(charactersIn: "-_")).first ?? sysCode // normalize
    }
}
