//LocationSharingSettingsView.swift
import SwiftUI
import CoreLocation

struct LocationSharingSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var peopleService = PeopleLocationService.shared
    @State private var isCheckedIn: Bool = false
    @State private var selectedSharingMode: UserLocation.LocationSharingMode = .manual
    @State private var selectedAccuracyLevel: UserLocation.AccuracyLevel = .radius5km
    @State private var autoCheckoutRadius: Double = 5.0
    @State private var showingCheckinOptions = false
    
    private let accuracyLevels: [(level: UserLocation.AccuracyLevel, name: String)] = [
        (.exact, "Dokładna"),
        (.approximate, "Przybliżona (500m)"),
        (.radius1km, "1 km"),
        (.radius5km, "5 km"),
        (.radius10km, "10 km"),
        (.radius15km, "15 km")
    ]
    
    private let sharingModes: [(mode: UserLocation.LocationSharingMode, name: String)] = [
        (.continuous, "Ciągły"),
        (.periodic, "Okresowy"),
        (.manual, "Manualny"),
        (.disabled, "Wyłączony")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Status meldowania
                Section(header: Text("Status")) {
                    HStack {
                        Image(systemName: isCheckedIn ? "location.fill" : "location")
                        Toggle(isCheckedIn ? "Zameldowany" : "Niezameldowany", isOn: $isCheckedIn)
                            .onChange(of: isCheckedIn) { newValue in
                                if newValue {
                                    showingCheckinOptions = true
                                } else {
                                    // Call check-out method directly on the service
                                    if var settings = peopleService.userLocationSettings {
                                        settings.checkInStatus.isCheckedIn = false
                                        peopleService.userLocationSettings = settings
                                    }
                                    isCheckedIn = false
                                }
                            }
                    }
                    
                    // Use optional chaining and nil-coalescing
                    if let checkInTime = peopleService.userLocationSettings?.checkInStatus.checkinTime {
                        Text("Zameldowany od: \(formatDate(checkInTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tryb udostępniania
                Section(header: Text("Tryb udostępniania")) {
                    Picker("Tryb", selection: $selectedSharingMode) {
                        ForEach(sharingModes, id: \.mode) { item in
                            Text(item.name).tag(item.mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedSharingMode) { newMode in
                        peopleService.updateSharingMode(newMode)
                    }
                }
                
                // Dokładność lokalizacji
                Section(header: Text("Dokładność lokalizacji"),
                        footer: Text("Określa, jak dokładnie inni będą widzieć Twoją lokalizację")) {
                    Picker("Dokładność", selection: $selectedAccuracyLevel) {
                        ForEach(accuracyLevels, id: \.level) { item in
                            Text(item.name).tag(item.level)
                        }
                    }
                    .onChange(of: selectedAccuracyLevel) { newLevel in
                        // Update visibility settings
                        if var settings = peopleService.userLocationSettings {
                            settings.visibilitySettings.accuracyLevel = newLevel
                            peopleService.userLocationSettings = settings
                        }
                    }
                }
                
                // Automatyczne wymeldowanie
                Section(header: Text("Automatyczne wymeldowanie"),
                        footer: Text("Zostaniesz automatycznie wymeldowany po opuszczeniu tego obszaru")) {
                    VStack(alignment: .leading) {
                        Text("Promień wymeldowania: \(Int(autoCheckoutRadius)) km")
                        Slider(value: $autoCheckoutRadius, in: 1...20, step: 1)
                            .onChange(of: autoCheckoutRadius) { newValue in
                                // Update auto checkout radius
                                if var settings = peopleService.userLocationSettings {
                                    settings.autoCheckoutRadius = newValue
                                    peopleService.userLocationSettings = settings
                                }
                            }
                    }
                }
            }
            .navigationTitle("Ustawienia lokalizacji")
            .navigationBarItems(trailing: Button("Gotowe") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingCheckinOptions) {
                CheckInOptionsView(isCheckedIn: $isCheckedIn)
            }
            .onAppear {
                // Initialize state from service
                if let settings = peopleService.userLocationSettings {
                    selectedSharingMode = settings.sharingMode
                    selectedAccuracyLevel = settings.visibilitySettings.accuracyLevel
                    autoCheckoutRadius = settings.autoCheckoutRadius
                    isCheckedIn = settings.checkInStatus.isCheckedIn
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Widok opcji meldowania
struct CheckInOptionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var peopleService = PeopleLocationService.shared
    @Binding var isCheckedIn: Bool
    @State private var selectedDuration: TimeInterval = 3600
    
    private let durations: [(interval: TimeInterval, name: String)] = [
        (3600, "1 godzina"),
        (7200, "2 godziny"),
        (14400, "4 godziny"),
        (28800, "8 godzin"),
        (86400, "24 godziny")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Czas zameldowania")) {
                    Picker("Czas", selection: $selectedDuration) {
                        ForEach(durations, id: \.interval) { duration in
                            Text(duration.name).tag(duration.interval)
                        }
                    }
                }
                
                Section {
                    Button("Zamelduj się") {
                        // Use current location to check in
                        if let location = peopleService.currentLocation?.coordinate {
                            // Update check-in status in userLocationSettings
                            if var settings = peopleService.userLocationSettings {
                                settings.checkInStatus.isCheckedIn = true
                                settings.checkInStatus.checkinTime = Date()
                                peopleService.userLocationSettings = settings
                            }
                            
                            isCheckedIn = true
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Zameldowanie")
            .navigationBarItems(trailing: Button("Anuluj") {
                isCheckedIn = false
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

