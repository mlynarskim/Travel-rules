import Foundation
import CoreLocation
import MapKit
import Combine
    //import FirebaseFirestore
//import FirebaseFirestoreSwift
import Darwin

public class PeopleLocationService: ObservableObject {
    @Published public var nearbyUsers: [NearbyUser] = []
    @Published public var selectedRadius: Double = 5.0
    @Published public var currentLocation: CLLocation?
    @Published public var searchCategory: NearbyUser.UserCategory?
    @Published public var userLocationSettings: UserLocation?
    @Published public var isCheckedIn: Bool = false
    @Published public var selectedStatus: NearbyUser.UserStatus?
    @Published public var selectedHelpTypes: Set<NearbyUser.HelpType> = []
    @Published public var showOnlyAvailable: Bool = false

    private var monitoredRegions: [String: CLCircularRegion] = [:]
    private var locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var autoCheckoutTimer: Timer?
    
    // Instancja Firestore
    private let db = Firestore.firestore()
    
    public static let shared = PeopleLocationService()
    
    public func getLocationCircle(for user: NearbyUser) -> MKCircle {
        return MKCircle(center: user.location, radius: user.shareLevel.radius)
    }
    
    private init() {
        self.locationManager = LocationManager()
        setupLocationUpdates()
        setupMockData()
        setupInitialLocationSettings()
    }
    
    private func setupInitialLocationSettings() {
        userLocationSettings = UserLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            sharingMode: .manual,
            visibilitySettings: .init(accuracyLevel: .radius5km),
            checkInStatus: .init(),
            autoCheckoutRadius: 5.0
        )
    }
    
    public enum AccuracyLevel {
        case exact
        case radius500m
        case radius1km
        case radius5km
        
        var radiusInMeters: Double {
            switch self {
            case .exact: return 0
            case .radius500m: return 500
            case .radius1km: return 1000
            case .radius5km: return 5000
            }
        }
    }
    
    private func createRegion(at location: CLLocationCoordinate2D) -> CLCircularRegion {
        let identifier = "checkin-\(UUID().uuidString)"
        let radius = userLocationSettings?.visibilitySettings.accuracyLevel.radiusInMeters ?? 500
        return CLCircularRegion(
            center: location,
            radius: radius,
            identifier: identifier
        )
    }
    
    public func updateSharingMode(_ mode: UserLocation.LocationSharingMode) {
        userLocationSettings?.sharingMode = mode
        if mode == .continuous {
            startLocationUpdates()
        } else if mode == .disabled {
            stopLocationUpdates()
        }
    }
    
    public func checkIn(at location: CLLocationCoordinate2D, duration: TimeInterval? = nil) {
        guard var settings = userLocationSettings else { return }
        
        settings.checkInStatus.isCheckedIn = true
        settings.checkInStatus.checkinTime = Date()
        settings.checkInStatus.lastLocation = location
        
        let region = createRegion(at: location)
        locationManager.startMonitoringRegion(center: location, radius: region.radius)
        monitoredRegions[region.identifier] = region
        
        if let duration = duration {
            settings.checkInStatus.plannedCheckoutTime = Date().addingTimeInterval(duration)
            setupAutoCheckout(after: duration)
        }
        
        userLocationSettings = settings
        isCheckedIn = true
        updateNearbyUsers()
    }
    
    public func checkOut() {
        guard var settings = userLocationSettings else { return }
        
        settings.checkInStatus.isCheckedIn = false
        settings.checkInStatus.checkinTime = nil
        settings.checkInStatus.plannedCheckoutTime = nil
        settings.checkInStatus.lastLocation = nil
        
        monitoredRegions.forEach { _, region in
            locationManager.stopMonitoringCurrentRegion()
        }
        monitoredRegions.removeAll()
        
        userLocationSettings = settings
        isCheckedIn = false
        autoCheckoutTimer?.invalidate()
        updateNearbyUsers()
    }
    
    public func updateVisibilitySettings(accuracyLevel: UserLocation.AccuracyLevel) {
        userLocationSettings?.visibilitySettings.accuracyLevel = accuracyLevel
        
        if let location = userLocationSettings?.checkInStatus.lastLocation {
            monitoredRegions.forEach { _, region in
                locationManager.stopMonitoringCurrentRegion()
            }
            monitoredRegions.removeAll()
            
            if userLocationSettings?.checkInStatus.isCheckedIn == true {
                checkIn(at: location)
            }
        }
        
        updateNearbyUsers()
    }
    
    private func setupAutoCheckout(after duration: TimeInterval) {
        autoCheckoutTimer?.invalidate()
        autoCheckoutTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.checkOut()
        }
    }
    
    private func checkForAutoCheckout() {
        guard let settings = userLocationSettings,
              settings.checkInStatus.isCheckedIn,
              let lastLocation = settings.checkInStatus.lastLocation,
              let currentLoc = currentLocation else { return }
        
        let distance = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
            .distance(from: currentLoc) / 1000.0 // Convert to kilometers
        
        if distance > settings.autoCheckoutRadius {
            checkOut()
        }
    }
    
    // MARK: - Filtering Management
    
    public func updateFilters(
        status: NearbyUser.UserStatus?,
        helpTypes: Set<NearbyUser.HelpType>,
        showOnlyAvailable: Bool
    ) {
        self.selectedStatus = status
        self.selectedHelpTypes = helpTypes
        self.showOnlyAvailable = showOnlyAvailable
        updateNearbyUsers()
    }
    
    public func resetFilters() {
        selectedRadius = 15.0
        searchCategory = nil
        selectedStatus = nil
        selectedHelpTypes = []
        showOnlyAvailable = false
        updateNearbyUsers()
    }
    
    // MARK: - Location Updates
    
    private func setupLocationUpdates() {
        locationManager.$locationData
            .sink { [weak self] locationData in
                if let lastLocation = locationData.last {
                    let location = CLLocation(
                        latitude: lastLocation.latitude,
                        longitude: lastLocation.longitude
                    )
                    self?.currentLocation = location
                    self?.checkForAutoCheckout()
                    self?.updateNearbyUsers()
                }
            }
            .store(in: &cancellables)
        
        locationManager.startUpdatingLocation()
    }
    
    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Users Management
    
    public func refreshUsers() {
        updateNearbyUsers()
    }
    
    public func refreshData() {
        print("Odświeżanie danych...")
        print("Obecnie dostępni użytkownicy: \(nearbyUsers.count)")
        nearbyUsers.forEach { user in
            print(" - \(user.name) (odległość: \(user.distance) km)")
        }
        updateNearbyUsers()
        print("Po odświeżeniu: \(nearbyUsers.count) użytkowników")
    }
    
    public func updateSearchRadius(_ radius: Double) {
        selectedRadius = radius
        updateNearbyUsers()
    }
    
    public func setCategory(_ category: NearbyUser.UserCategory?) {
        searchCategory = category
        updateNearbyUsers()
    }
    
    private func updateNearbyUsers() {
        guard let userLocation = currentLocation else {
            print("Brak aktualnej lokalizacji użytkownika")
            return
        }
        
        var updatedUsers = mockUsers.map { user -> NearbyUser in
            var updatedUser = user
            let userLoc = CLLocation(
                latitude: user.location.latitude,
                longitude: user.location.longitude
            )
            
            updatedUser.distance = userLoc.distance(from: userLocation) / 1000.0
            
            if let settings = userLocationSettings {
                if userLocationSettings?.visibilitySettings.approvedUsers[user.id] == true {
                    updatedUser.shareLevel = .exact
                } else {
                    let blurredLocation = settings.getVisibleLocation(for: user.id)
                    updatedUser.location = blurredLocation
                }
            }
            
            return updatedUser
        }
        
        // Aplikujemy wszystkie filtry
        updatedUsers = updatedUsers.filter { user in
            let distanceFilter = user.distance <= selectedRadius
            let categoryFilter = searchCategory == nil || user.category == searchCategory
            let statusFilter = selectedStatus == nil || user.status == selectedStatus
            let helpTypesFilter = selectedHelpTypes.isEmpty ||
                                  !user.helpOffered.filter { selectedHelpTypes.contains($0) }.isEmpty
            let availabilityFilter = !showOnlyAvailable || user.status == .available
            let approvedFilter = userLocationSettings?.visibilitySettings.visibleTo != .approved ||
                                 userLocationSettings?.visibilitySettings.approvedUsers[user.id] == true
            
            return distanceFilter && categoryFilter && statusFilter &&
                   helpTypesFilter && availabilityFilter && approvedFilter
        }
        
        updatedUsers.sort { $0.distance < $1.distance }
        
        DispatchQueue.main.async {
            self.nearbyUsers = updatedUsers
            print("Zaktualizowano listę użytkowników: \(self.nearbyUsers.count)")
        }
    }
    
    // MARK: - Mock Data
    
    private var mockUsers: [NearbyUser] = []
    
    private func setupMockData() {
        mockUsers = [
            NearbyUser(
                id: UUID(),
                name: "Jan Kowalski",
                status: .offering,
                category: .help,
                location: CLLocationCoordinate2D(latitude: 51.237049, longitude: 20.017532),
                distance: 10.5,
                shareLevel: .approximate,
                description: "Chętnie pomogę z naprawą samochodu",
                helpOffered: [.technical, .tools],
                lastActiveTime: Date(),
                automaticCheckIn: true
            ),
            NearbyUser(
                id: UUID(),
                name: "Marek Markowski",
                status: .available,
                category: .technical,
                location: CLLocationCoordinate2D(latitude: 53.237049, longitude: 21.017532),
                distance: 0.5,
                shareLevel: .approximate,
                description: "Mechanik z doświadczeniem",
                helpOffered: [.technical, .tools, .transport],
                lastActiveTime: Date(),
                automaticCheckIn: false
            ),
            NearbyUser(
                id: UUID(),
                name: "Anna Nowak",
                status: .needsHelp,
                category: .social,
                location: CLLocationCoordinate2D(latitude: 52.237149, longitude: 20.017632),
                distance: 5.5,
                shareLevel: .exact,
                description: "Szukam towarzystwa na spacery",
                helpOffered: [.social],
                lastActiveTime: Date(),
                automaticCheckIn: true
            ),
            NearbyUser(
                id: UUID(),
                name: "Rodzina Kowalscy",
                status: .available,
                category: .family,
                location: CLLocationCoordinate2D(latitude: 52.237049, longitude: 20.027532),
                distance: 7.5,
                shareLevel: .approximate,
                description: "Rodzina z dziećmi, chętnie poznamy innych",
                helpOffered: [.childcare, .social],
                lastActiveTime: Date(),
                automaticCheckIn: false
            ),
            NearbyUser(
                id: UUID(),
                name: "Kamper Team",
                status: .offering,
                category: .camping,
                location: CLLocationCoordinate2D(latitude: 52.234049, longitude: 20.015532),
                distance: 3.2,
                shareLevel: .exact,
                description: "Doświadczeni kamperowicze, chętnie pomożemy",
                helpOffered: [.technical, .resources],
                lastActiveTime: Date(),
                automaticCheckIn: true
            )
        ]
    }
    
    // MARK: - User Interactions
    
    public func requestUserDetails(_ userId: UUID) -> NearbyUser? {
        return mockUsers.first { $0.id == userId }
    }
    
    public func requestLocationSharing(with userId: UUID) {
        guard let user = mockUsers.first(where: { $0.id == userId }) else { return }
        print("Requesting exact location from: \(user.name)")
    }
    
    public func approveLocationRequest(from userId: UUID) {
        userLocationSettings?.visibilitySettings.approvedUsers[userId] = true
        updateNearbyUsers()
    }
    
    public func blockUser(_ userId: UUID) {
        mockUsers.removeAll { $0.id == userId }
        userLocationSettings?.visibilitySettings.approvedUsers.removeValue(forKey: userId)
        updateNearbyUsers()
    }
    
    public func reportUser(_ userId: UUID, reason: String) {
        guard let user = mockUsers.first(where: { $0.id == userId }) else { return }
        print("Reported user \(user.name). Reason: \(reason)")
    }
    
    // MARK: - Aktualizacja profilu użytkownika
    /// Aktualizuje profil użytkownika w Firestore na podstawie przekazanych danych.
    func updateProfile(_ updatedProfile: UserProfile) {
        do {
            try db.collection("users").document(updatedProfile.id).setData(from: updatedProfile, merge: true) { error in
                if let error = error {
                    print("Błąd aktualizacji profilu w Firestore: \(error)")
                } else {
                    print("Profil zaktualizowany w Firestore.")
                    // Po udanej aktualizacji możesz odświeżyć dane, np. wywołując updateNearbyUsers()
                    self.updateNearbyUsers()
                }
            }
        } catch {
            print("Błąd podczas serializacji profilu: \(error)")
        }
    }
}

private struct FilterPreferences: Codable {
    let radius: Double
    let category: NearbyUser.UserCategory?
    let status: NearbyUser.UserStatus?
    let helpTypes: Set<NearbyUser.HelpType>
    let showOnlyAvailable: Bool
}
