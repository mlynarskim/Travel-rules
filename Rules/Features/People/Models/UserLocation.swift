//UserLocation.swift
import Foundation
import CoreLocation

public struct UserLocation: Codable {
    public let id: UUID
    public var coordinate: CLLocationCoordinate2D
    public var timestamp: Date
    public var sharingMode: LocationSharingMode
    public var visibilitySettings: VisibilitySettings
    public var checkInStatus: CheckInStatus
    public var autoCheckoutRadius: Double // w kilometrach
    
    // Tryby udostępniania lokalizacji
    public enum LocationSharingMode: String, Codable {
        case continuous // Ciągłe (aktualizacja co 30-60 min)
        case periodic // Okresowe (na określony czas)
        case manual // Manualne meldowanie
        case disabled // Wyłączone
        
        public var updateInterval: TimeInterval {
            switch self {
            case .continuous: return 30 * 60 // 30 minut
            case .periodic: return 60 * 60 // 1 godzina
            case .manual: return 0
            case .disabled: return 0
            }
        }
    }
    
    // Ustawienia widoczności
    public struct VisibilitySettings: Codable {
        public var accuracyLevel: AccuracyLevel
        public var visibleTo: VisibilityLevel
        public var approvedUsers: [UUID: Bool]

        public init(
            accuracyLevel: AccuracyLevel = .approximate,
            visibleTo: VisibilityLevel = .all,
            approvedUsers: [UUID: Bool] = [:]
        ) {
            self.accuracyLevel = accuracyLevel
            self.visibleTo = visibleTo
            self.approvedUsers = approvedUsers
        }
    }
    // Poziomy dokładności lokalizacji
    public enum AccuracyLevel: String, Codable {
        case exact
        case approximate
        case radius1km
        case radius5km
        case radius10km
        case radius15km
        
        public var radiusInMeters: Double {
            switch self {
            case .exact: return 0
            case .approximate: return 500
            case .radius1km: return 1000
            case .radius5km: return 5000
            case .radius10km: return 10000
            case .radius15km: return 15000
            }
        }
    }
    
    // Poziomy widoczności
    public enum VisibilityLevel: String, Codable {
        case all // Wszyscy
        case approved // Tylko zatwierdzeni
        case none // Nikt
    }
    
    // Status zameldowania
    public struct CheckInStatus: Codable {
        public var isCheckedIn: Bool
        public var checkinTime: Date?
        public var plannedCheckoutTime: Date?
        public var lastLocation: CLLocationCoordinate2D?
        
        public init(
            isCheckedIn: Bool = false,
            checkinTime: Date? = nil,
            plannedCheckoutTime: Date? = nil,
            lastLocation: CLLocationCoordinate2D? = nil
        ) {
            self.isCheckedIn = isCheckedIn
            self.checkinTime = checkinTime
            self.plannedCheckoutTime = plannedCheckoutTime?.timeIntervalSinceNow ?? 0 > 0 ? plannedCheckoutTime : nil
            self.lastLocation = lastLocation
        }
    }
    
    public init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        timestamp: Date = Date(),
        sharingMode: LocationSharingMode = .manual,
        visibilitySettings: VisibilitySettings = VisibilitySettings(),
        checkInStatus: CheckInStatus = CheckInStatus(),
        autoCheckoutRadius: Double = 5.0
    ) {
        self.id = id
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.sharingMode = sharingMode
        self.visibilitySettings = visibilitySettings
        self.checkInStatus = checkInStatus
        self.autoCheckoutRadius = max(0, min(autoCheckoutRadius, 100))
    }
    
    // Metody pomocnicze
    public func shouldBeVisible(to userId: UUID) -> Bool {
        switch visibilitySettings.visibleTo {
        case .all:
            return true
        case .approved:
            return visibilitySettings.approvedUsers[userId] == true // Sprawdza obecność i wartość
        case .none:
            return false
        }
    }
    public func getVisibleLocation(for userId: UUID) -> CLLocationCoordinate2D {
        guard shouldBeVisible(to: userId) else {
            return applyAccuracyLevel(to: coordinate) // Zastosuj rozmycie zamiast zwracania dokładnej lokalizacji
        }
        
        if visibilitySettings.approvedUsers[userId] == true {
            return coordinate // Zwróć dokładną lokalizację
        }
        
        return applyAccuracyLevel(to: coordinate) // Zastosuj poziom rozmycia
    }
    
    private func applyAccuracyLevel(to coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let radius = visibilitySettings.accuracyLevel.radiusInMeters
        if radius == 0 { return coordinate }
        
        let randomRadius = Double.random(in: 0...radius)
        let randomAngle = Double.random(in: 0...(2 * .pi))
        
        let earthRadius = 6371000.0 // Promień Ziemi w metrach
        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(randomRadius / earthRadius) +
                        cos(lat1) * sin(randomRadius / earthRadius) * cos(randomAngle))
        
        let lon2 = lon1 + atan2(sin(randomAngle) * sin(randomRadius / earthRadius) * cos(lat1),
                                cos(randomRadius / earthRadius) - sin(lat1) * sin(lat2))
        
        // Ograniczenie współrzędnych
        let latitude = min(max(lat2 * 180 / .pi, -90), 90)
        let longitude = min(max(lon2 * 180 / .pi, -180), 180)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

