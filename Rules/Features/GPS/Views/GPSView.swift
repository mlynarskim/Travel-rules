// Features/GPS/Views/GPSView.swift
import SwiftUI
import CoreLocation
import MapKit
import UIKit

// Bottom bar tabs for GPS screen
private enum GPSBottomTab: String, CaseIterable {
    // ✅ kolejność: mapa -> plan -> info
    case explore
    case plan
    case info

    var systemImage: String {
        switch self {
        case .info: return "info.circle"
        case .explore: return "map"
        case .plan: return "sparkles"
        }
    }

    // NOTE: Add these keys to Localizable.strings (PL/EN/ES)
    var titleKey: String {
        switch self {
        case .info: return "gps_tab_info"
        case .explore: return "gps_tab_explore"
        case .plan: return "gps_tab_plan"
        }
    }
}

struct GPSView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var description = ""
    @State private var currentLocation: CLLocation?
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @StateObject private var languageManager = LanguageManager.shared
    @State private var isCountryInfoExpanded = false

    // ✅ mapa jako pierwszy ekran
    @State private var selectedBottomTab: GPSBottomTab = .explore

    @State private var followUserOnMap: Bool = true
    @State private var hasSetInitialRegion: Bool = false
    @State private var exploreRefreshID: UUID = UUID()
    @State private var infoMapPosition: MapCameraPosition = .automatic

    // 🔥 licznik zapisanych miejsc + osiągnięcia
    @AppStorage("totalLocationsSaved") private var totalLocationsSaved: Int = 0
    private let achievementManager = AchievementManager.shared

    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        case .autumn: return ThemeColors.autumnTheme
        case .winter: return ThemeColors.winterTheme
        case .summer: return ThemeColors.summerTheme
        case .spring: return ThemeColors.springTheme
        }
    }

    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667
    }

    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                    .resizable()
                    .ignoresSafeArea()

                // Main content depends on the selected bottom tab
                Group {
                    switch selectedBottomTab {
                    case .info:
                        infoTabContent
                    case .explore:
                        exploreTabContent
                    case .plan:
                        planTabContent
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
                bottomBar
            }
            .navigationBarHidden(false)
        }
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance

            withAnimation {
                locationManager.startUpdatingLocation()
            }
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onReceive(locationManager.$lastLocation) { location in
            guard let location else { return }

            currentLocation = location

            // Ustaw region tylko na starcie lub gdy użytkownik chce śledzić lokalizację.
            if followUserOnMap || !hasSetInitialRegion {
                hasSetInitialRegion = true
                let newRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                withAnimation(.easeInOut(duration: 0.25)) {
                    infoMapPosition = .region(newRegion)
                }
            }
        }
    }

    // MARK: - Tabs content

    private var infoTabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: isSmallDevice ? 12 : 16) {
                CurrentLocationCard(
                    currentLocation: currentLocation,
                    themeColors: themeColors,
                    isSmallDevice: isSmallDevice
                )
                .transition(AnyTransition.scale)

                Map(position: $infoMapPosition) {
                    UserAnnotation()
                    ForEach(locationManager.locationData) { item in
                        Annotation(
                            item.description,
                            coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
                        ) {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .foregroundColor(colorForMarker(item.markerColor))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                .frame(height: isSmallDevice ? 150 : 200)
                .frame(maxWidth: isSmallDevice ? 300 : 380)
                .cornerRadius(15)
                .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                .disabled(true)

                if !locationManager.currentCountry.isEmpty {
                    CountryInfoCard(
                        countryName: locationManager.currentCountry,
                        isExpanded: $isCountryInfoExpanded,
                        countryInfo: locationManager.countryInfoService.countryInfo,
                        themeColors: themeColors,
                        isSmallDevice: isSmallDevice
                    )
                }

                // Panel wprowadzania lokalizacji
                LocationInputPanel(
                    description: $description,
                    currentLocation: currentLocation,
                    locationManager: locationManager,
                    themeColors: themeColors,
                    isSmallDevice: isSmallDevice,
                    // ✅ po zapisie miejsca – zwiększ licznik i odpal osiągnięcie
                    onSaved: {
                        totalLocationsSaved &+= 1
                        // zarejestruj liczbę zapisanych lokalizacji (wewnętrzna logika progu 1+)
                        achievementManager.recordLocationsCount(totalLocationsSaved)
                        // dodatkowe, jawne sprawdzenie osiągnięć po stronie managera (tylko lokalizacje)
                        achievementManager.checkAchievements(
                            rulesDrawn: 0,
                            rulesSaved: 0,
                            rulesShared: 0,
                            locationsSaved: totalLocationsSaved
                        )
                    }
                )
            }
            .padding(.top, isSmallDevice ? 8 : 16)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private var exploreTabContent: some View {
        ExploreMapTab(
            currentLocation: currentLocation,
            savedLocations: locationManager.locationData,
            themeColors: themeColors,
            isSmallDevice: isSmallDevice,
            isDarkMode: isDarkMode,
            followUserOnMap: $followUserOnMap
        )
        .id(exploreRefreshID)
    }

    private var planTabContent: some View {
        PlanBuilderTab(
            themeColors: themeColors,
            isSmallDevice: isSmallDevice,
            isDarkMode: isDarkMode,
            currentLocation: currentLocation
        )
    }

    // MARK: - Bottom bar (mniejszy + poprawny kontrast w każdym motywie)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background((isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08)))

            HStack {
                ForEach(GPSBottomTab.allCases, id: \.self) { tab in
                    bottomBarButton(for: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, isSmallDevice ? 8 : 12)
            .padding(.top, isSmallDevice ? 6 : 8)
            .padding(.bottom, isSmallDevice ? 6 : 8)
            .background(themeColors.cardBackground)
            .shadow(color: themeColors.cardShadow, radius: 6, x: 0, y: -2)
        }
    }

    private func bottomBarButton(for tab: GPSBottomTab) -> some View {
        let isSelected = (selectedBottomTab == tab)

        // ✅ kontrast zależny od realnego tła, nie od isDarkMode
        let lightBG = isLightColor(themeColors.cardBackground)
        let selectedColor: Color = lightBG ? .black : .white
        let unselectedColor: Color = lightBG ? .black.opacity(0.65) : .white.opacity(0.85)

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                selectedBottomTab = tab
            }

            if tab == .explore {
                // Wymuś odświeżenie mapy po wejściu w zakładkę.
                exploreRefreshID = UUID()
            }
            if tab == .info {
                followUserOnMap = true
            }

            HapticManager.shared.impact(style: .light)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: isSmallDevice ? 18 : 20, weight: .semibold))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)

                Text(tab.titleKey.appLocalized)
                    .font(.system(size: isSmallDevice ? 11 : 12, weight: .semibold))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Capsule()
                    .fill(isSelected ? themeColors.primary : Color.clear)
                    .frame(width: isSmallDevice ? 22 : 26, height: 3)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func colorForMarker(_ marker: String) -> Color {
        switch marker {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        default: return .red
        }
    }
}

struct MapFallbackView: View {
    @Binding var region: MKCoordinateRegion

    var body: some View {
        Text("map_not_available".appLocalized)
            .font(.system(size: 16))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
    }
}

struct CurrentLocationCard: View {
    let currentLocation: CLLocation?
    let themeColors: ThemeColors
    let isSmallDevice: Bool

    var body: some View {
        VStack(spacing: isSmallDevice ? 8 : 10) {
            Text("current_location".appLocalized)
                .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                .foregroundColor(.white)

            if let location = currentLocation {
                VStack(spacing: isSmallDevice ? 4 : 5) {
                    Text("\("latitude".appLocalized): \(String(format: "%.6f", location.coordinate.latitude))")
                        .font(.system(size: isSmallDevice ? 14 : 16))
                    Text("\("longitude".appLocalized): \(String(format: "%.6f", location.coordinate.longitude))")
                        .font(.system(size: isSmallDevice ? 14 : 16))
                }
                .foregroundColor(.white)
                .contextMenu {
                    Button(action: {
                        let text = "Lat: \(String(format: "%.6f", location.coordinate.latitude)), Lon: \(String(format: "%.6f", location.coordinate.longitude))"
                        UIPasteboard.general.string = text
                    }) {
                        Label("copy_location".localized, systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("waiting_location".appLocalized)
                    .font(.system(size: isSmallDevice ? 14 : 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: isSmallDevice ? 300 : 350)
        .padding(isSmallDevice ? 12 : 16)
        .background(themeColors.primary)
        .cornerRadius(15)
        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
    }
}

struct CountryInfoCard: View {
    let countryName: String
    @Binding var isExpanded: Bool
    let countryInfo: CountryInfo?
    let themeColors: ThemeColors
    let isSmallDevice: Bool

    var body: some View {
        VStack(spacing: isSmallDevice ? 8 : 10) {
            Button(action: {
                withAnimation(.spring()) { isExpanded.toggle() }
                HapticManager.shared.impact(style: .light)
            }) {
                HStack {
                    Text(countryName.isEmpty ? "waiting_for_country".appLocalized : "country_location".appLocalized + countryName)
                        .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        .animation(.spring(), value: isExpanded)
                }
                .padding(isSmallDevice ? 12 : 16)
                .frame(maxWidth: isSmallDevice ? 300 : 380)
                .background(themeColors.primary)
                .cornerRadius(15)
            }
            .buttonStyle(.plain)

            if isExpanded, let info = countryInfo {
                CountryInfoDetails(
                    info: info,
                    themeColors: themeColors,
                    isSmallDevice: isSmallDevice
                )
                .transition(AnyTransition.scale.combined(with: .opacity))
            }
        }
    }
}

struct CountryInfoDetails: View {
    let info: CountryInfo
    let themeColors: ThemeColors
    let isSmallDevice: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isSmallDevice ? 12 : 15) {
            VStack(alignment: .leading, spacing: isSmallDevice ? 6 : 8) {
                Text("emergency_numbers".appLocalized)
                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                    .foregroundColor(.white)

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: isSmallDevice ? 6 : 8) {
                    GridRow {
                        Text("📞 \("general".appLocalized): \(info.emergencyNumbers.general)")
                        Text("👮 \("police".appLocalized): \(info.emergencyNumbers.police)")
                    }
                    GridRow {
                        Text("🚑 \("ambulance".appLocalized): \(info.emergencyNumbers.ambulance)")
                        Text("🚒 \("fire".appLocalized): \(info.emergencyNumbers.fire)")
                    }
                }
                .font(.system(size: isSmallDevice ? 14 : 16))
                .foregroundColor(.white)
            }

            if !info.usefulLinks.isEmpty {
                Divider().background(Color.white)

                VStack(alignment: .leading, spacing: isSmallDevice ? 6 : 8) {
                    Text("useful_links".appLocalized)
                        .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                        .foregroundColor(.white)
                    ForEach(info.usefulLinks, id: \.url) { link in
                        Link(destination: URL(string: link.url)!) {
                            Text("🔗 \(link.title)")
                                .underline()
                                .foregroundColor(.white)
                                .font(.system(size: isSmallDevice ? 14 : 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let embassy = info.embassyInfo {
                Divider().background(Color.white)
                Text("embassy_information".appLocalized)
                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                    .foregroundColor(.white)
                Text("🏛 \(embassy)")
                    .font(.system(size: isSmallDevice ? 14 : 16))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: isSmallDevice ? 300 : 380)
        .padding(isSmallDevice ? 12 : 16)
        .background(themeColors.primary)
        .cornerRadius(15)
    }
}

struct LocationInputPanel: View {
    @Binding var description: String
    let currentLocation: CLLocation?
    let locationManager: LocationManager
    let themeColors: ThemeColors
    let isSmallDevice: Bool

    // ✅ callback z rodzica – co zrobić po udanym zapisie
    let onSaved: () -> Void

    // wybór koloru pinezki
    @State private var selectedMarkerColor: String = "red"
    private let availableColors = ["red", "green", "blue", "orange", "purple", "yellow", "pink", "brown", "gray", "black"]

    var body: some View {
        VStack(spacing: isSmallDevice ? 12 : 15) {
            TextField("description".appLocalized, text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: isSmallDevice ? 14 : 16))
                .padding(.horizontal)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(availableColors, id: \.self) { color in
                    Circle()
                        .fill(colorForMarker(color))
                        .frame(width: 25, height: 25)
                        .overlay(
                            Circle().stroke(selectedMarkerColor == color ? Color.black : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture { selectedMarkerColor = color }
                }
            }
            .padding(.vertical, 5)

            HStack(spacing: isSmallDevice ? 16 : 20) {
                Button(action: saveLocation) {
                    Text("save_location".appLocalized)
                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: isSmallDevice ? 100 : 180, height: isSmallDevice ? 36 : 44)
                        .background(themeColors.primary)
                        .cornerRadius(15)
                        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                NavigationLink(
                    destination: SavedLocationsView(
                        locationData: Binding(
                            get: { locationManager.locationData },
                            set: { locationManager.locationData = $0 }
                        ),
                        deleteAction: locationManager.deleteLocation
                    )
                ) {
                    Text("locations".appLocalized)
                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: isSmallDevice ? 100 : 120, height: isSmallDevice ? 36 : 44)
                        .background(themeColors.primary)
                        .cornerRadius(15)
                        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: isSmallDevice ? 300 : 340)
        .padding(isSmallDevice ? 12 : 16)
        .background(themeColors.cardBackground)
        .cornerRadius(15)
    }

    private func saveLocation() {
        guard let location = currentLocation, !description.isEmpty else { return }

        withAnimation(.spring()) {
            let newLocation = LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                description: description,
                markerColor: selectedMarkerColor
            )
            locationManager.locationData.append(newLocation)
            description = ""
            locationManager.saveLocations()
            HapticManager.shared.impact(style: .medium)
            onSaved()
        }
    }

    private func colorForMarker(_ color: String) -> Color {
        switch color {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        default: return .red
        }
    }
}

struct GPSView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GPSView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE")

            GPSView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
                .previewDisplayName("iPhone 14 Pro Max")
                .environment(\.colorScheme, .dark)
        }
    }
}
