// Features/GPS/Views/GPSExploreMapTab.swift
import SwiftUI
import CoreLocation
import MapKit
import UIKit

// MARK: - Explore categories (MapKit)

fileprivate enum ExploreCategory: String, CaseIterable, Hashable, Identifiable {
    case attractions
    case mustSee
    case restaurants
    case cafes
    case parking
    case petFriendly
    case kids
    case shops
    case accommodation
    case camperService
    case toilets
    case water
    case gas

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .attractions: return "🏛️"
        case .mustSee: return "⭐️"
        case .restaurants: return "🍽️"
        case .cafes: return "☕️"
        case .parking: return "🅿️"
        case .petFriendly: return "🐾"
        case .kids: return "🛝"
        case .shops: return "🛒"
        case .accommodation: return "🛏️"
        case .camperService: return "🛠️"
        case .toilets: return "🚻"
        case .water: return "🚰"
        case .gas: return "⛽️"
        }
    }

    // NOTE: Add these keys to Localizable.strings (PL/EN/ES)
    var titleKey: String {
        switch self {
        case .attractions: return "gps_cat_attractions"
        case .mustSee: return "gps_cat_must_see"
        case .restaurants: return "gps_cat_restaurants"
        case .cafes: return "gps_cat_cafes"
        case .parking: return "gps_cat_parking"
        case .petFriendly: return "gps_cat_pet_friendly"
        case .kids: return "gps_cat_kids"
        case .shops: return "gps_cat_shops"
        case .accommodation: return "gps_cat_accommodation"
        case .camperService: return "gps_cat_camper_service"
        case .toilets: return "gps_cat_toilets"
        case .water: return "gps_cat_water"
        case .gas: return "gps_cat_gas"
        }
    }

    /// MapKit POI categories when available (best quality)
    var poiCategories: [MKPointOfInterestCategory] {
        switch self {
        case .restaurants: return [.restaurant]
        case .cafes: return [.cafe, .bakery]
        case .parking: return [.parking]
        case .shops: return [.store, .foodMarket]
        case .accommodation: return [.hotel, .campground]
        case .toilets: return [.restroom]
        case .gas: return [.gasStation]
        case .attractions: return [.museum, .park, .nationalPark, .zoo, .aquarium, .amusementPark]
        case .mustSee: return [.museum, .park, .nationalPark, .theater, .stadium]
        case .petFriendly, .kids, .camperService, .water:
            return []
        }
    }

    /// Fallback search terms (used when POI categories are not enough / not available)
    /// We intentionally include multi-language keywords to improve results in PL/EN/ES.
    var queryTerms: [String] {
        switch self {
        case .petFriendly:
            return ["pet friendly", "dog friendly", "perros bienvenidos", "psy mile widziane", "przyjazne psom"]
        case .kids:
            return ["plac zabaw", "playground", "para niños", "dla dzieci", "family friendly"]
        case .camperService:
            return ["serwis kampera", "camper service", "RV service", "dump station", "zrzut", "water refill"]
        case .water:
            return ["woda", "water", "agua", "kran", "water refill"]
        case .mustSee:
            return ["punkt widokowy", "viewpoint", "mirador", "atrakcje", "landmark"]
        case .gas:
            return ["stacja paliw", "gas station", "fuel", "gasolinera", "paliwo"]
        case .restaurants:
            return ["restauracja", "restaurant", "jedzenie", "comida"]
        case .cafes:
            return ["kawiarnia", "cafe", "coffee", "cafetería"]
        case .parking:
            return ["parking", "parkowanie", "aparcamiento"]
        case .shops:
            return ["sklep", "store", "supermarket", "tienda"]
        case .accommodation:
            return ["nocleg", "hotel", "hostel", "camping", "alojamiento"]
        case .toilets:
            return ["toaleta", "wc", "restroom", "baño"]
        case .attractions:
            return ["atrakcja", "museum", "muzeum", "park", "zoo", "aquarium"]
        }
    }
}

fileprivate struct ExploreAnnotation: Identifiable, Hashable {
    enum Kind: Hashable {
        case poi
        case saved(String) // markerColor
    }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String?
    let icon: String
    let kind: Kind
    let mapItem: MKMapItem?

    static func == (lhs: ExploreAnnotation, rhs: ExploreAnnotation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
fileprivate final class ExplorePOIViewModel: ObservableObject {
    @Published private(set) var annotations: [ExploreAnnotation] = []
    @Published var isLoading: Bool = false

    private var lastSearchToken: UUID?

    func clear() {
        annotations = []
    }

    func search(
        region: MKCoordinateRegion,
        selectedCategories: Set<ExploreCategory>
    ) {
        guard !selectedCategories.isEmpty else {
            clear()
            return
        }

        let token = UUID()
        lastSearchToken = token
        isLoading = true

        let categories = Array(selectedCategories)
        let poiCats = Set(categories.flatMap { $0.poiCategories })
        let textQueries = categories.flatMap { $0.queryTerms }

        var requests: [MKLocalSearch.Request] = []

        if !poiCats.isEmpty {
            let req = MKLocalSearch.Request()
            req.region = region
            req.resultTypes = .pointOfInterest
            req.pointOfInterestFilter = MKPointOfInterestFilter(including: Array(poiCats))
            requests.append(req)
        }

        for q in Array(Set(textQueries)).prefix(4) { // cap for performance
            let req = MKLocalSearch.Request()
            req.region = region
            req.resultTypes = .pointOfInterest
            req.naturalLanguageQuery = q
            requests.append(req)
        }

        if requests.isEmpty {
            clear()
            isLoading = false
            return
        }

        Task {
            var collected: [ExploreAnnotation] = []

            for req in requests {
                let items = await self.runSearch(req)
                if self.lastSearchToken != token { return }

                for item in items {
                    let name = item.name ?? ""
                    let coord = item.placemark.coordinate
                    let subtitle = item.placemark.title
                    let key = "\(name.lowercased())_\(String(format: "%.4f", coord.latitude))_\(String(format: "%.4f", coord.longitude))"
                    let icon = self.icon(for: item)

                    collected.append(
                        ExploreAnnotation(
                            id: key,
                            coordinate: coord,
                            title: name.isEmpty ? "POI" : name,
                            subtitle: subtitle,
                            icon: icon,
                            kind: .poi,
                            mapItem: item
                        )
                    )
                }
            }

            if self.lastSearchToken != token { return }

            var seen = Set<String>()
            let unique = collected.filter { seen.insert($0.id).inserted }

            self.annotations = Array(unique.prefix(80))
            self.isLoading = false
        }
    }

    private func icon(for item: MKMapItem) -> String {
        // 1) POI category
        if let cat = item.pointOfInterestCategory {
            switch cat {
            case .restaurant: return "🍽️"
            case .cafe, .bakery: return "☕️"
            case .parking: return "🅿️"
            case .gasStation: return "⛽️"
            case .restroom: return "🚻"
            case .hotel, .campground: return "🛏️"
            case .store, .foodMarket: return "🛒"
            case .park, .nationalPark: return "🌳"
            case .museum, .theater: return "🏛️"
            case .zoo, .aquarium: return "🐾"
            case .amusementPark: return "🎢"
            default: break
            }
        }

        // 2) Heurystyka po nazwie/adresie (PL/EN/ES)
        let hay = ((item.name ?? "") + " " + (item.placemark.title ?? "")).lowercased()
        if hay.contains("plac zabaw") || hay.contains("playground") || hay.contains("kids") || hay.contains("niños") {
            return "🛝"
        }
        if hay.contains("pet") || hay.contains("dog") || hay.contains("pies") || hay.contains("perro") {
            return "🐾"
        }
        if hay.contains("woda") || hay.contains("water") || hay.contains("agua") {
            return "🚰"
        }

        return "📍"
    }

    private func runSearch(_ request: MKLocalSearch.Request) async -> [MKMapItem] {
        await withCheckedContinuation { cont in
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let items = response?.mapItems, error == nil {
                    cont.resume(returning: items)
                } else {
                    cont.resume(returning: [])
                }
            }
        }
    }
}

// MARK: - Explore UI

struct ExploreMapTab: View { // <- musi być widoczne dla GPSView (dlatego nie private)
    let currentLocation: CLLocation?
    let savedLocations: [LocationData]
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let isDarkMode: Bool
    @Binding var followUserOnMap: Bool

    @State private var radiusSelection: Int = 10 // 5/10/15 km, -1 = viewport
    @State private var showFiltersSheet: Bool = false
    @State private var selectedCategories: Set<ExploreCategory> = [.attractions, .restaurants]

    @State private var selectedAnnotation: ExploreAnnotation? = nil
    @State private var debounceWorkItem: DispatchWorkItem? = nil

    @State private var isProgrammaticMove: Bool = false
    @StateObject private var vm = ExplorePOIViewModel()

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(combinedAnnotations) { item in
                    Annotation(item.title, coordinate: item.coordinate, anchor: .bottom) {
                        Button {
                            selectedAnnotation = item
                            HapticManager.shared.impact(style: .light)
                        } label: {
                            annotationView(for: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .onMapCameraChange { ctx in
                mapRegion = ctx.region
                if !isProgrammaticMove {
                    followUserOnMap = false
                }
                if radiusSelection == -1 { scheduleSearch(immediate: false) }
            }
            .onAppear {
                applyRadiusToMapIfNeeded()
                scheduleSearch(immediate: true)
            }
            .onChange(of: radiusSelection) { _, _ in
                applyRadiusToMapIfNeeded()
                scheduleSearch(immediate: true)
            }
            .onChange(of: selectedCategories) { _, _ in
                scheduleSearch(immediate: false)
            }
            .onChange(of: currentLocation) { _, _ in
                if followUserOnMap { applyRadiusToMapIfNeeded() }
            }
            .overlay(alignment: .top) {
                if currentLocation == nil {
                    let lightBG = isLightColor(themeColors.cardBackground)
                    let fg: Color = lightBG ? .black : .white

                    Text("gps_explore_no_location".appLocalized)
                        .font(.system(size: isSmallDevice ? 12 : 14, weight: .semibold))
                        .foregroundColor(fg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeColors.cardBackground)
                        .cornerRadius(14)
                        .padding(.top, 10)
                        .padding(.horizontal)
                }
            }

            if vm.isLoading {
                VStack {
                    ProgressView()
                        .tint(isDarkMode ? .white : .black)
                        .padding(10)
                        .background(themeColors.cardBackground)
                        .cornerRadius(14)
                        .shadow(color: themeColors.cardShadow, radius: 6, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 14)
                .padding(.top, 14)
            }

            VStack(spacing: 10) {
                Button {
                    centerOnUser()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(themeColors.primary)
                        .clipShape(Circle())
                        .shadow(color: themeColors.cardShadow, radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                Button {
                    showFiltersSheet = true
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(themeColors.primary)
                        .clipShape(Circle())
                        .shadow(color: themeColors.cardShadow, radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 14)
            .padding(.bottom, isSmallDevice ? 90 : 100)
        }
        .sheet(isPresented: $showFiltersSheet) {
            ExploreFiltersSheet(
                radiusSelection: $radiusSelection,
                selectedCategories: $selectedCategories,
                themeColors: themeColors,
                isSmallDevice: isSmallDevice,
                isDarkMode: isDarkMode
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedAnnotation) { item in
            ExplorePlaceDetailsSheet(
                item: item,
                themeColors: themeColors,
                isSmallDevice: isSmallDevice,
                isDarkMode: isDarkMode
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var combinedAnnotations: [ExploreAnnotation] {
        let saved = savedLocations.map { loc in
            ExploreAnnotation(
                id: "saved_\(String(describing: loc.id))",
                coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                title: loc.description,
                subtitle: nil,
                icon: "📍",
                kind: .saved(loc.markerColor),
                mapItem: nil
            )
        }
        return vm.annotations + saved
    }

    private func scheduleSearch(immediate: Bool) {
        debounceWorkItem?.cancel()

        let work = DispatchWorkItem { runSearchNow() }
        debounceWorkItem = work

        let delay: TimeInterval = immediate ? 0.05 : 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func runSearchNow() {
        guard currentLocation != nil else {
            vm.clear()
            return
        }
        let searchRegion = computeSearchRegion()
        vm.search(region: searchRegion, selectedCategories: selectedCategories)
    }

    private func computeSearchRegion() -> MKCoordinateRegion {
        // -1 => viewport mode
        if radiusSelection == -1 {
            return mapRegion
        }

        let km = max(1, radiusSelection)
        let meters = Double(km) * 1000.0

        let center = followUserOnMap ? (currentLocation?.coordinate ?? mapRegion.center) : mapRegion.center

        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: meters * 2.0,
            longitudinalMeters: meters * 2.0
        )
    }

    private func applyRadiusToMapIfNeeded() {
        guard radiusSelection != -1 else { return }
        guard let loc = currentLocation else { return }

        let km = max(1, radiusSelection)
        let meters = Double(km) * 1000.0

        isProgrammaticMove = true
        followUserOnMap = true

        let newRegion = MKCoordinateRegion(
            center: loc.coordinate,
            latitudinalMeters: meters * 2.0,
            longitudinalMeters: meters * 2.0
        )
        mapRegion = newRegion
        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(newRegion)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isProgrammaticMove = false
        }
    }

    private func centerOnUser() {
        guard let loc = currentLocation else { return }

        isProgrammaticMove = true
        followUserOnMap = true

        let newRegion = MKCoordinateRegion(
            center: loc.coordinate,
            latitudinalMeters: Double(max(1, radiusSelection)) * 2_000.0,
            longitudinalMeters: Double(max(1, radiusSelection)) * 2_000.0
        )
        mapRegion = newRegion
        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(newRegion)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isProgrammaticMove = false
        }

        HapticManager.shared.impact(style: .light)
        scheduleSearch(immediate: true)
    }

    @ViewBuilder
    private func annotationView(for item: ExploreAnnotation) -> some View {
        switch item.kind {
        case .saved(let markerColor):
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .foregroundColor(colorForMarker(markerColor))
                .frame(width: 28, height: 28)
        case .poi:
            Text(item.icon)
                .font(.system(size: 18))
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(themeColors.primary)
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.65), lineWidth: 1)
                )
                .shadow(color: themeColors.cardShadow, radius: 4, x: 0, y: 2)
        }
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

fileprivate struct ExploreFiltersSheet: View {
    @Binding var radiusSelection: Int
    @Binding var selectedCategories: Set<ExploreCategory>
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let isDarkMode: Bool

    var body: some View {
        let lightBG = isLightColor(themeColors.cardBackground)
        let titleColor: Color = lightBG ? .black : .white

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("gps_explore_filters_title".appLocalized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(titleColor)

                VStack(alignment: .leading, spacing: 10) {
                    Text("gps_explore_radius".appLocalized)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(titleColor)

                    Picker("gps_explore_radius".appLocalized, selection: $radiusSelection) {
                        Text("5 km").tag(5)
                        Text("10 km").tag(10)
                        Text("15 km").tag(15)
                        Text("gps_explore_radius_viewport".appLocalized).tag(-1)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                Text("gps_explore_categories".appLocalized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(titleColor)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: isSmallDevice ? 2 : 3),
                    spacing: 10
                ) {
                    ForEach(ExploreCategory.allCases) { cat in
                        categoryChip(cat)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        selectedCategories = Set(ExploreCategory.allCases)
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Text("gps_explore_select_all".appLocalized)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(themeColors.primary)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedCategories.removeAll()
                        HapticManager.shared.impact(style: .light)
                    } label: {
                        Text("gps_explore_clear".appLocalized)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(themeColors.primary.opacity(0.65))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }

                Text("gps_explore_hint".appLocalized)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer(minLength: 10)
            }
            .padding(16)
        }
        .background(themeColors.cardBackground)
    }

    private func categoryChip(_ cat: ExploreCategory) -> some View {
        let isSelected = selectedCategories.contains(cat)

        return Button {
            if isSelected {
                selectedCategories.remove(cat)
            } else {
                selectedCategories.insert(cat)
            }
            HapticManager.shared.impact(style: .light)
        } label: {
            HStack(spacing: 8) {
                Text(cat.icon)
                Text(cat.titleKey.appLocalized)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? themeColors.primary : themeColors.primary.opacity(isDarkMode ? 0.25 : 0.18))
            )
        }
        .buttonStyle(.plain)
    }
}

fileprivate struct ExplorePlaceDetailsSheet: View {
    let item: ExploreAnnotation
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let isDarkMode: Bool

    var body: some View {
        let lightBG = isLightColor(themeColors.cardBackground)
        let titleColor: Color = lightBG ? .black : .white

        VStack(alignment: .leading, spacing: 14) {
            Text(item.title)
                .font(.system(size: isSmallDevice ? 18 : 20, weight: .bold))
                .foregroundColor(titleColor)

            if let subtitle = item.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: isSmallDevice ? 13 : 15))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    openInAppleMaps()
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Label("open_apple_maps".appLocalized, systemImage: "map")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(themeColors.primary)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)

                Button {
                    copyCoordinates()
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Label("copy_location".appLocalized, systemImage: "doc.on.doc")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(themeColors.primary.opacity(0.65))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }

            Text("gps_explore_disclaimer".appLocalized)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(themeColors.cardBackground)
    }

    private func openInAppleMaps() {
        let placemark = MKPlacemark(coordinate: item.coordinate)
        let mapItem = item.mapItem ?? MKMapItem(placemark: placemark)
        mapItem.name = item.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func copyCoordinates() {
        let text = "Lat: \(String(format: "%.6f", item.coordinate.latitude)), Lon: \(String(format: "%.6f", item.coordinate.longitude))"
        UIPasteboard.general.string = text
    }
}
