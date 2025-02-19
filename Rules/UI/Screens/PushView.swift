import SwiftUI
import UserNotifications

// MARK: - DocumentEntry
struct DocumentEntry: Identifiable, Hashable, Codable {
    let id = UUID()
    let date: Date
    let document: String
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
    @State private var selectedDocument = "Dowód osobisty"
    
    // Lista zapisanych dokumentów:
    @State private var savedDocuments: [DocumentEntry] = [] {
        didSet {
            saveDocuments()
            scheduleDocumentNotifications()
        }
    }
    
    // Wybór typu dokumentów, np. w Pickerze:
    private let documentOptions = [
        "Dowód osobisty", "Paszport", "Ubezpieczenie zdrowotne", "Polisa ubezpieczeniowa",
        "Karty płatnicze", "Wiza", "Karta EKUZ", "Książeczka szczepień",
        "Prawo jazdy", "Międzynarodowe prawo jazdy", "Ubezpieczenie OC"
    ]
    
    // Tu zdefiniuj swoje motywy/themes:
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeColors.secondary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Nagłówek:
                    HStack {
                       Spacer()
                       Spacer()
                       Text("notification_settings".appLocalized).font(.title).foregroundColor(themeColors.primaryText).padding()
                       Spacer()
                       Button(action: { showPushView = false }) { Image(systemName: "xmark.circle").font(.system(size: 24)).foregroundColor(themeColors.primaryText).padding() }
                    }
                    
                    // Główna sekcja: opisy + przełączniki + dodawanie dokumentów
                    VStack(spacing: 20) {
                        
                        // Krótki opis + przełącznik głównych (codziennych) powiadomień
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Powiadomienia o zasadach")
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
                                                    // Ustaw dzienny alarm
                                                    NotificationManager.instance.scheduleNotification()
                                                }
                                            }
                                        }
                                    } else {
                                        // Usuń dzienne powiadomienia
                                        NotificationManager.instance.removeNotification(identifier: "daily_rule_notification")
                                    }
                                }
                                .padding()
                                .tint(themeColors.primary)
                                .foregroundColor(themeColors.primaryText)
                                .background(themeColors.cardBackground)
                                .cornerRadius(10)
                        }
                        
                        // Krótki opis + przełącznik powiadomień miesięcznych
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Powiadomienia o ważności dokumentów")
                                .foregroundColor(themeColors.primaryText)
                                .font(.subheadline)
                            
                            Toggle("enable_monthly_reminder".appLocalized, isOn: $isMonthlyReminderEnabled)
                                .onChange(of: isMonthlyReminderEnabled) { _, newValue in
                                    UserDefaults.standard.set(newValue, forKey: "isMonthlyReminderEnabled")
                                    if newValue {
                                        // Ustaw powiadomienie co miesiąc
                                        scheduleDocumentNotifications()
                                    } else {
                                        // Usuń powiadomienie co miesiąc
                                        NotificationManager.instance.removeNotification(identifier: "monthly_document_check")
                                    }
                                }
                                .padding()
                                .tint(themeColors.primary)
                                .foregroundColor(themeColors.primaryText)
                                .background(themeColors.cardBackground)
                                .cornerRadius(10)
                        }
                        
                        // Pole wyboru daty
                        DatePicker("Wybierz datę", selection: $selectedDate, displayedComponents: [.date])
                            .padding()
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                            .foregroundColor(themeColors.primaryText)
                        
                        // Picker dokumentu
                        Picker("Wybierz dokument", selection: $selectedDocument) {
                            ForEach(documentOptions, id: \.self) { document in
                                Text(document).tag(document)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(themeColors.cardBackground)
                        .cornerRadius(10)
                        .foregroundColor(themeColors.primaryText)
                        
                        // Przycisk zapisu dokumentu do listy (z blokadą duplikatów)
                        Button("Zapisz") {
                            // Blokada duplikatów: sprawdzamy, czy jest już zapisany dokument z taką samą datą
                            let isDuplicate = savedDocuments.contains(where: {
                                $0.document == selectedDocument && Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
                            })
                            
                            guard !isDuplicate else {
                                // Jeśli wolisz, możesz wyświetlać alert
                                print("Ten dokument z taką samą datą już istnieje, pomijam dodawanie.")
                                return
                            }
                            
                            let newEntry = DocumentEntry(date: selectedDate, document: selectedDocument)
                            savedDocuments.append(newEntry)
                        }
                        .padding()
                        .background(themeColors.primary)
                        .foregroundColor(themeColors.secondary)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Lista dokumentów
                    List {
                        ForEach(savedDocuments) { entry in
                            HStack {
                                Text("\(entry.document) - \(entry.date, formatter: dateFormatter)")
                                Spacer()
                                Button(action: {
                                    savedDocuments.removeAll { $0.id == entry.id }
                                    // Ewentualnie usuń powiadomienia, jeśli chcesz, aby zniknęły przy usunięciu wszystkich dokumentów
                                    NotificationManager.instance.removeNotification(identifier: "monthly_document_check")
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding()
                    .listStyle(.plain)
                    
                    Spacer()
                }
            }
            .onAppear {
                // Ładujemy dokumenty z UserDefaults
                loadDocuments()
                // Aktualizujemy/ustawiamy powiadomienie, jeśli włączone
                scheduleDocumentNotifications()
            }
            // Odświeżanie widoku po zmianie języka
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                viewRefresh.toggle()
            }
            .id(viewRefresh)
        }
    }
    
    // Formatter wyświetlania dat w liście
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    // Zapis dokumentów w UserDefaults (JSON)
    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(savedDocuments) {
            UserDefaults.standard.set(encoded, forKey: "savedDocuments")
        }
    }
    
    // Odczyt dokumentów z UserDefaults (JSON)
    private func loadDocuments() {
        if let savedData = UserDefaults.standard.data(forKey: "savedDocuments"),
           let decoded = try? JSONDecoder().decode([DocumentEntry].self, from: savedData) {
            self.savedDocuments = decoded
        }
    }
    
    // Ustawia powiadomienie na pierwszy dzień miesiąca o 9:00
    // Jeśli isMonthlyReminderEnabled == true, to utworzy/odświeży
    // powiadomienie "monthly_document_check" z listą aktualnych dokumentów
    private func scheduleDocumentNotifications() {
        guard isMonthlyReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Twoje dokumenty stracą ważność"
        
        // Tworzymy listę dokumentów z datami
        let docLines = savedDocuments.map {
            "\($0.document) - \(dateFormatter.string(from: $0.date))"
        }.joined(separator: "\n")
        
        // Jeśli ktoś nie doda żadnego dokumentu:
        content.body = docLines.isEmpty ? "Brak dodanych dokumentów" : docLines
        content.sound = .default
        
        // Pierwszy dzień miesiąca, godzina 9
        var dateComponents = DateComponents()
        dateComponents.day = 19
        dateComponents.hour = 12
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly_document_check", content: content, trigger: trigger)
        
        // Dodajemy/odświeżamy powiadomienie
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Błąd przy dodawaniu miesięcznego powiadomienia: \(error)")
            }
        }
    }
}

