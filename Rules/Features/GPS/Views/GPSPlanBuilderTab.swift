// Features/GPS/Views/GPSPlanBuilderTab.swift
import SwiftUI
import CoreLocation
@preconcurrency import MapKit
import UIKit
import Foundation

// MARK: - Models

fileprivate struct PlanStep: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem?
    let snapshot: UIImage?
    let distanceMeters: Double

    static func == (lhs: PlanStep, rhs: PlanStep) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var distanceText: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters)) m"
        } else {
            return String(format: "%.1f km", distanceMeters / 1000)
        }
    }
}

fileprivate struct PlanBlueprint {
    /// Kluczowe kategorie POI — wyszukiwane jako pierwsze, wyniki mają priorytet
    let primaryCats: [MKPointOfInterestCategory]
    /// Kluczowe zapytania — wyszukiwane jako pierwsze
    let primaryQueries: [String]
    /// Uzupełniające kategorie — tylko jeśli wyników z primary jest mniej niż 4
    let supplementaryCats: [MKPointOfInterestCategory]
    /// Uzupełniające zapytania — tylko jeśli wyników z primary jest mniej niż 4
    let supplementaryQueries: [String]

    init(primaryCats: [MKPointOfInterestCategory] = [],
         primaryQueries: [String] = [],
         supplementaryCats: [MKPointOfInterestCategory] = [],
         supplementaryQueries: [String] = []) {
        self.primaryCats = primaryCats
        self.primaryQueries = primaryQueries
        self.supplementaryCats = supplementaryCats
        self.supplementaryQueries = supplementaryQueries
    }
}

// MARK: - ViewModel

@MainActor
fileprivate final class PlanBuilderViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var suggestions: [PlanStep] = []
    @Published var errorMessage: String? = nil
    @Published var showExhaustedAlert = false

    private var allCandidates: [MKMapItem] = []
    private var seenIDs: Set<String> = []
    private var lastPlanKey = ""
    private var lastRadiusKM = 0

    private var searchCache: [String: ([MKMapItem], Date)] = [:]
    private var snapshotCache: [String: UIImage] = [:]
    private var placePreviewCache: [String: UIImage] = [:]

    nonisolated static let debugPlans = false
    nonisolated private func dbg(_ msg: String) {
        guard Self.debugPlans else { return }
        print("[GPSPlan] \(msg)")
    }

    private final class LocalSearchHolder: @unchecked Sendable {
        let search: MKLocalSearch
        init(_ search: MKLocalSearch) { self.search = search }
    }

    // MARK: - Session

    func resetSession() {
        seenIDs = []
        allCandidates = []
        suggestions = []
        errorMessage = nil
        lastPlanKey = ""
        lastRadiusKM = 0
    }

    // MARK: - Generate

    func generate(planKey: String, from location: CLLocation?, radiusKM: Int) {
        errorMessage = nil
        showExhaustedAlert = false

        guard let location else {
            errorMessage = "gps_plan_error_no_location"
            return
        }

        let paramsChanged = planKey != lastPlanKey || radiusKM != lastRadiusKM
        if paramsChanged {
            dbg("Params changed — reset session")
            seenIDs = []
            allCandidates = []
            lastPlanKey = planKey
            lastRadiusKM = radiusKM
        }

        isLoading = true
        let center = location.coordinate
        let maxDistanceMeters = Double(radiusKM) * 1_000.0
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: maxDistanceMeters * 2,
            longitudinalMeters: maxDistanceMeters * 2
        )
        let blueprint = makeBlueprint(for: planKey)

        Task {
            // Fetch candidates only once per session
            if allCandidates.isEmpty {
                allCandidates = await fetchCandidates(
                    blueprint: blueprint,
                    region: region,
                    center: center,
                    maxDistanceMeters: maxDistanceMeters,
                    radiusKM: radiusKM
                )
                dbg("Fetched \(allCandidates.count) total candidates")
            }

            // Pick next 4 unseen
            let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let available = allCandidates.filter { item in
                let pid = makePlaceID(name: item.name ?? "", coord: item.placemark.coordinate)
                return !seenIDs.contains(pid)
            }

            dbg("Available unseen: \(available.count)")

            guard !available.isEmpty else {
                if !seenIDs.isEmpty {
                    showExhaustedAlert = true
                } else {
                    errorMessage = "gps_plan_error_no_results"
                }
                isLoading = false
                return
            }

            let batch = Array(available.prefix(4))
            var newSteps: [PlanStep] = []

            for (i, item) in batch.enumerated() {
                let coord = item.placemark.coordinate
                let name = item.name ?? ""
                let pid = makePlaceID(name: name, coord: coord)
                seenIDs.insert(pid)

                let dist = centerLoc.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                let snap = await placePreviewImage(for: item, coordinate: coord)

                newSteps.append(PlanStep(
                    id: "\(pid)_\(i)",
                    title: name,
                    subtitle: cleanSubtitle(item.placemark.title),
                    coordinate: coord,
                    mapItem: item,
                    snapshot: snap,
                    distanceMeters: dist
                ))
            }

            self.suggestions = newSteps
            self.isLoading = false
            dbg("Showing \(newSteps.count) suggestions, seen total: \(seenIDs.count)")
        }
    }

    // Remove redundant address parts from subtitle
    private func cleanSubtitle(_ title: String?) -> String? {
        guard let t = title, !t.isEmpty else { return nil }
        // MKPlacemark.title often returns "Name, Street, City" — show only street+city
        let parts = t.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count >= 2 {
            return parts.dropFirst().joined(separator: ", ")
        }
        return t
    }

    // MARK: - Blueprint factory

    private func makeBlueprint(for planKey: String) -> PlanBlueprint {
        switch planKey {

        case "plan_walk":
            // Atrakcje spacerowe: parki, muzea, plaże, punkty widokowe
            return PlanBlueprint(
                primaryCats: [.park, .nationalPark, .beach, .museum, .theater, .library],
                primaryQueries: ["viewpoint punkt widokowy panorama scenic walk szlak spacer zabytek"],
                supplementaryCats: [.movieTheater],
                supplementaryQueries: ["kawiarnia cafe coffee"]
            )

        case "plan_bike":
            // Trasy rowerowe i parki — bez sklepów/restauracji
            return PlanBlueprint(
                primaryCats: [.park, .nationalPark],
                primaryQueries: ["trasa rowerowa bike route cycleway ścieżka rowerowa bicycle path velo"],
                supplementaryCats: [.beach],
                supplementaryQueries: ["bike trail park nature szlak rowerowy"]
            )

        case "plan_sunset":
            // Miejsca z widokiem na zachód słońca: plaże, mariny, tarasy
            return PlanBlueprint(
                primaryCats: [.beach, .marina, .nationalPark],
                primaryQueries: ["sunset zachód słońca viewpoint punto panoramico mirador rooftop taras widokowy"],
                supplementaryCats: [.park],
                supplementaryQueries: ["panorama viewpoint wzgórze hill hilltop"]
            )

        case "plan_with_dog":
            // Miejsca przyjazne psom: wybiegi, parki, ścieżki
            return PlanBlueprint(
                primaryCats: [.park, .nationalPark],
                primaryQueries: ["dog park wybieg dla psów hundepark parque para perros dog run dog walk dog friendly"],
                supplementaryCats: [.beach],
                supplementaryQueries: ["spacer z psem dog trail pet friendly park nature walk"]
            )

        case "plan_with_kids":
            // Atrakcje dla dzieci: place zabaw, zoo, parki rozrywki
            return PlanBlueprint(
                primaryCats: [.amusementPark, .zoo, .aquarium],
                primaryQueries: ["plac zabaw playground parque infantil sala zabaw trampoliny kids activity centrum rozrywki dla dzieci"],
                supplementaryCats: [.park, .museum],
                supplementaryQueries: ["family park muzeum interaktywne kids family attraction"]
            )

        case "plan_vanlife_stop":
            // Miejsca noclegowe i postojowe dla kamperów
            return PlanBlueprint(
                primaryCats: [.campground],
                primaryQueries: ["camping campground stellplatz aire camping-car camper park rv park nocleg kamper motorhome caravan overnight parking"],
                supplementaryCats: [.parking],
                supplementaryQueries: ["parking dla kamperów campervan parking 24h truck stop MOP miejsce odpoczynku"]
            )

        case "plan_chill":
            // Kawiarnie, wina, browary — czas relaksu
            return PlanBlueprint(
                primaryCats: [.cafe, .bakery, .winery, .brewery],
                primaryQueries: ["kawiarnia specialty coffee wine bar lounge terrace ogródek"],
                supplementaryCats: [.nightlife, .restaurant],
                supplementaryQueries: ["ice cream gelato lody bistro"]
            )

        case "plan_nature":
            // Dzika przyroda i rezerwaty
            return PlanBlueprint(
                primaryCats: [.nationalPark, .park],
                primaryQueries: ["nature reserve rezerwat przyrody scenic trail hiking szlak turystyczny viewpoint waterfall wodospad"],
                supplementaryCats: [.beach, .marina],
                supplementaryQueries: ["scenic area krajobraz przyrodniczy laguna jezioro lake"]
            )

        default:
            return PlanBlueprint(
                primaryCats: [.park, .museum, .beach],
                primaryQueries: ["viewpoint atrakcja park"],
                supplementaryCats: [.theater],
                supplementaryQueries: []
            )
        }
    }

    // MARK: - Fetch candidates

    private func fetchCandidates(
        blueprint: PlanBlueprint,
        region: MKCoordinateRegion,
        center: CLLocationCoordinate2D,
        maxDistanceMeters: CLLocationDistance,
        radiusKM: Int
    ) async -> [MKMapItem] {
        let regionKey = "\(String(format: "%.3f", center.latitude))_\(String(format: "%.3f", center.longitude))_r\(radiusKM)"
        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let maxD = maxDistanceMeters * 1.05
        var merged: [String: (MKMapItem, CLLocationDistance)] = [:]

        // Helper to add items to merged dict
        func addItems(_ items: [MKMapItem]) {
            for item in items {
                guard let c = validCoord(item), isWithin(c, center: centerLoc, maxD: maxD) else { continue }
                let d = centerLoc.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
                let pid = makePlaceID(name: item.name ?? "", coord: c)
                if (merged[pid]?.1 ?? .infinity) > d { merged[pid] = (item, d) }
            }
        }

        // 1. Primary POI categories
        if !blueprint.primaryCats.isEmpty {
            let req = MKLocalSearch.Request()
            req.region = region
            req.resultTypes = .pointOfInterest
            req.pointOfInterestFilter = MKPointOfInterestFilter(including: blueprint.primaryCats)
            let key = "poi|\(regionKey)|\(blueprint.primaryCats.map { $0.rawValue }.sorted().joined(separator: ","))"
            let items = await runItems(req, cacheKey: key)
            dbg("Primary POI search: \(items.count) items")
            addItems(items)
        }

        // 2. Primary natural language queries
        for query in blueprint.primaryQueries {
            let req = MKLocalSearch.Request()
            req.region = region
            req.resultTypes = [.pointOfInterest, .address]
            req.naturalLanguageQuery = query
            let key = "q|\(regionKey)|\(query.lowercased())"
            let items = await runItems(req, cacheKey: key)
            dbg("Primary query '\(query)': \(items.count) items")
            try? await Task.sleep(nanoseconds: 80_000_000)
            addItems(items)
        }

        // 3. Supplementary search only if < 4 primary results found
        if merged.count < 4 {
            dbg("Only \(merged.count) primary results — searching supplementary")

            if !blueprint.supplementaryCats.isEmpty {
                let req = MKLocalSearch.Request()
                req.region = region
                req.resultTypes = .pointOfInterest
                req.pointOfInterestFilter = MKPointOfInterestFilter(including: blueprint.supplementaryCats)
                let key = "poi|\(regionKey)|\(blueprint.supplementaryCats.map { $0.rawValue }.sorted().joined(separator: ","))"
                let items = await runItems(req, cacheKey: key)
                dbg("Supplementary POI search: \(items.count) items")
                addItems(items)
            }

            for query in blueprint.supplementaryQueries {
                let req = MKLocalSearch.Request()
                req.region = region
                req.resultTypes = [.pointOfInterest, .address]
                req.naturalLanguageQuery = query
                let key = "q|\(regionKey)|\(query.lowercased())"
                let items = await runItems(req, cacheKey: key)
                dbg("Supplementary query '\(query)': \(items.count) items")
                try? await Task.sleep(nanoseconds: 80_000_000)
                addItems(items)
            }
        }

        // Sort by distance ascending — closest (most relevant) first
        return merged.values.sorted { $0.1 < $1.1 }.map { $0.0 }
    }

    private func validCoord(_ item: MKMapItem) -> CLLocationCoordinate2D? {
        let c = item.placemark.coordinate
        guard c.latitude != 0 || c.longitude != 0 else { return nil }
        return c
    }

    private func isWithin(_ coord: CLLocationCoordinate2D, center: CLLocation, maxD: Double) -> Bool {
        center.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) <= maxD
    }

    // MARK: - MapKit search with cache

    private func runItems(_ request: MKLocalSearch.Request, cacheKey: String) async -> [MKMapItem] {
        if let cached = searchCache[cacheKey], Date().timeIntervalSince(cached.1) < 300 {
            return cached.0
        }

        return await withCheckedContinuation { cont in
            let lock = NSLock()
            var finished = false

            func finish(_ items: [MKMapItem], timedOut: Bool) {
                lock.lock(); defer { lock.unlock() }
                guard !finished else { return }
                finished = true
                if !items.isEmpty && !timedOut {
                    Task { @MainActor in self.searchCache[cacheKey] = (items, Date()) }
                }
                cont.resume(returning: items)
            }

            let search = MKLocalSearch(request: request)
            let holder = LocalSearchHolder(search)

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.dbg("Timeout | \(cacheKey)")
                holder.search.cancel()
                finish([], timedOut: true)
            }

            search.start { [weak self] resp, err in
                if let e = err as NSError?,
                   !(e.domain == NSURLErrorDomain && e.code == NSURLErrorCancelled) {
                    self?.dbg("Error | \(e.domain) \(e.code)")
                }
                finish(resp?.mapItems ?? [], timedOut: false)
            }
        }
    }

    // MARK: - Key helpers

    private func makePlaceID(name: String, coord: CLLocationCoordinate2D) -> String {
        "\(name.lowercased())_\(String(format: "%.4f", coord.latitude))_\(String(format: "%.4f", coord.longitude))"
    }

    // MARK: - Snapshots

    private func placePreviewImage(for mapItem: MKMapItem, coordinate: CLLocationCoordinate2D) async -> UIImage? {
        let key = makePlaceID(name: mapItem.name ?? "", coord: coordinate)
        if let cached = placePreviewCache[key] { return cached }

        if let snap = await snapshotImage(for: coordinate) {
            placePreviewCache[key] = snap
            return snap
        }
        if let look = await lookAroundImage(for: coordinate) {
            placePreviewCache[key] = look
            return look
        }
        return nil
    }

    private func snapshotImage(for coordinate: CLLocationCoordinate2D) async -> UIImage? {
        let key = "\(String(format: "%.4f", coordinate.latitude))_\(String(format: "%.4f", coordinate.longitude))"
        if let cached = snapshotCache[key] { return cached }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
        options.size = CGSize(width: 200, height: 120)
        options.scale = UIScreen.main.scale
        options.mapType = .standard

        return await withCheckedContinuation { cont in
            MKMapSnapshotter(options: options).start(with: DispatchQueue.global(qos: .userInitiated)) { snap, _ in
                let img = snap?.image
                if let img { Task { @MainActor in self.snapshotCache[key] = img } }
                cont.resume(returning: img)
            }
        }
    }

    private func lookAroundImage(for coordinate: CLLocationCoordinate2D) async -> UIImage? {
        guard #available(iOS 16.0, *) else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            let lock = NSLock()
            var done = false
            func finish(_ img: UIImage?) {
                lock.lock(); defer { lock.unlock() }
                guard !done else { return }
                done = true
                cont.resume(returning: img)
            }
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.5) { finish(nil) }
            MKLookAroundSceneRequest(coordinate: coordinate).getSceneWithCompletionHandler { scene, _ in
                guard let scene else { finish(nil); return }
                let opts = MKLookAroundSnapshotter.Options()
                opts.size = CGSize(width: 200, height: 120)
                MKLookAroundSnapshotter(scene: scene, options: opts).getSnapshotWithCompletionHandler { snap, _ in
                    finish(snap?.image)
                }
            }
        }
    }
}

// MARK: - View

struct PlanBuilderTab: View {
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let isDarkMode: Bool
    let currentLocation: CLLocation?

    @State private var selectedPlan: String = "plan_walk"
    @State private var radiusKM: Int = 10

    @StateObject private var vm = PlanBuilderViewModel()

    var body: some View {
        let lightCard = isLightColor(themeColors.cardBackground)
        let cardTitle: Color = lightCard ? .black : .white
        let cardBody: Color = lightCard ? .black.opacity(0.7) : .white.opacity(0.8)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("gps_plan_title".appLocalized)
                        .font(.system(size: isSmallDevice ? 18 : 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("gps_plan_desc".appLocalized)
                        .font(.system(size: isSmallDevice ? 13 : 14))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Controls card
                VStack(alignment: .leading, spacing: 10) {
                    Text("gps_plan_choose".appLocalized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(cardBody)

                    Picker("gps_plan_choose".appLocalized, selection: $selectedPlan) {
                        Text("plan_walk".appLocalized).tag("plan_walk")
                        Text("plan_bike".appLocalized).tag("plan_bike")
                        Text("plan_sunset".appLocalized).tag("plan_sunset")
                        Text("plan_with_dog".appLocalized).tag("plan_with_dog")
                        Text("plan_with_kids".appLocalized).tag("plan_with_kids")
                        Text("plan_vanlife_stop".appLocalized).tag("plan_vanlife_stop")
                        Text("plan_chill".appLocalized).tag("plan_chill")
                        Text("plan_nature".appLocalized).tag("plan_nature")
                    }
                    .pickerStyle(.menu)
                    .tint(cardTitle)
                    .onChange(of: selectedPlan) { _, _ in vm.resetSession() }

                    Text("gps_plan_radius".appLocalized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(cardBody)

                    Picker("gps_plan_radius".appLocalized, selection: $radiusKM) {
                        Text("5 km").tag(5)
                        Text("10 km").tag(10)
                        Text("15 km").tag(15)
                        Text("20 km").tag(20)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: radiusKM) { _, _ in vm.resetSession() }

                    Button {
                        vm.generate(planKey: selectedPlan, from: currentLocation, radiusKM: radiusKM)
                        HapticManager.shared.impact(style: .medium)
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.85)
                            }
                            Text(vm.isLoading
                                 ? "gps_plan_generating".appLocalized
                                 : (vm.suggestions.isEmpty
                                    ? "gps_plan_generate".appLocalized
                                    : "gps_plan_next".appLocalized))
                                .font(.system(size: isSmallDevice ? 14 : 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: isSmallDevice ? 40 : 46)
                        .background(themeColors.primary)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
                }
                .padding(isSmallDevice ? 12 : 16)
                .background(themeColors.cardBackground)
                .cornerRadius(16)

                // Error banner
                if let err = vm.errorMessage {
                    Text(err.appLocalized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeColors.primary.opacity(0.35))
                        .cornerRadius(14)
                }

                // Results
                if vm.isLoading && vm.suggestions.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text("gps_plan_generating".appLocalized)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else if !vm.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("gps_plan_result_title".appLocalized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(cardTitle)
                            Spacer()
                            Text(planTypeIcon(selectedPlan))
                                .font(.system(size: 20))
                        }

                        ForEach(vm.suggestions) { step in
                            PlaceCard(
                                step: step,
                                themeColors: themeColors,
                                isSmallDevice: isSmallDevice,
                                cardTitle: cardTitle,
                                cardBody: cardBody
                            ) {
                                openInMaps(step)
                                HapticManager.shared.impact(style: .light)
                            }
                        }
                    }
                    .padding(isSmallDevice ? 12 : 16)
                    .background(themeColors.cardBackground)
                    .cornerRadius(16)
                }

                Spacer(minLength: 120)
            }
            .padding(.top, isSmallDevice ? 8 : 16)
            .padding(.horizontal)
        }
        .alert("gps_plan_exhausted_title".appLocalized, isPresented: $vm.showExhaustedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("gps_plan_exhausted_message".appLocalized)
        }
    }

    private func planTypeIcon(_ key: String) -> String {
        switch key {
        case "plan_walk":        return "🚶"
        case "plan_bike":        return "🚴"
        case "plan_sunset":      return "🌅"
        case "plan_with_dog":    return "🐕"
        case "plan_with_kids":   return "🧒"
        case "plan_vanlife_stop":return "🚐"
        case "plan_chill":       return "☕"
        case "plan_nature":      return "🌿"
        default:                 return "📍"
        }
    }

    private func openInMaps(_ step: PlanStep) {
        let placemark = MKPlacemark(coordinate: step.coordinate)
        let mapItem = step.mapItem ?? MKMapItem(placemark: placemark)
        mapItem.name = step.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

// MARK: - Place card

fileprivate struct PlaceCard: View {
    let step: PlanStep
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let cardTitle: Color
    let cardBody: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Map snapshot (wide)
                if let img = step.snapshot {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: isSmallDevice ? 90 : 110)
                        .clipped()
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                } else {
                    Rectangle()
                        .fill(themeColors.primary.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: isSmallDevice ? 60 : 70)
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                        .overlay(
                            Image(systemName: "map")
                                .foregroundColor(themeColors.primary.opacity(0.5))
                                .font(.system(size: 22))
                        )
                }

                // Info row
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title)
                            .font(.system(size: isSmallDevice ? 13 : 15, weight: .semibold))
                            .foregroundColor(cardTitle)
                            .lineLimit(1)

                        if let sub = step.subtitle, !sub.isEmpty {
                            Text(sub)
                                .font(.system(size: isSmallDevice ? 11 : 12))
                                .foregroundColor(cardBody)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    // Distance badge
                    Text(step.distanceText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeColors.primary)
                        .cornerRadius(8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(cardBody)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(themeColors.primary.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(themeColors.primary.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Corner radius helper

fileprivate extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

fileprivate struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

