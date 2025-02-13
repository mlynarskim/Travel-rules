import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentCountry: String = ""
    @Published var locationData: [LocationData] = []
    @Published var countryInfoService = CountryInfoService()
    @Published var currentRegion: CLCircularRegion? = nil
    @Published var lastLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        let status = locationManager.authorizationStatus
        if status == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        loadSavedLocations()
    }
    
    func startMonitoringRegion(center: CLLocationCoordinate2D, radius: Double) {
        guard radius <= locationManager.maximumRegionMonitoringDistance else {
            print("Region radius exceeds the allowable limit")
            return
        }
        stopMonitoringCurrentRegion()
        
        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: "userCheckInRegion"
        )
        region.notifyOnExit = true
        region.notifyOnEntry = true
        
        currentRegion = region
        locationManager.startMonitoring(for: region)
    }
    
    
    func stopMonitoringCurrentRegion() {
        if let region = currentRegion {
            locationManager.stopMonitoring(for: region)
            currentRegion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "userCheckInRegion" {
            NotificationCenter.default.post(
                name: .didEnterMonitoredRegion,
                object: nil,
                userInfo: ["region": region]
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "userCheckInRegion" {
            NotificationCenter.default.post(
                name: .didExitMonitoredRegion,
                object: nil,
                userInfo: ["region": region]
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        reverseGeocode(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Access to location denied. Stopping updates.")
                locationManager.stopUpdatingLocation()
            case .locationUnknown:
                print("Location unknown. Trying again...")
            default:
                print("Other error: \(clError.localizedDescription)")
            }
        } else {
            print("Location manager failed with error: \(error.localizedDescription)")
        }
    }
    
    private func loadSavedLocations() {
        if let savedData = UserDefaults.standard.data(forKey: "SavedLocations") {
            do {
                let decodedLocations = try JSONDecoder().decode([LocationData].self, from: savedData)
                locationData = decodedLocations
            } catch {
                print("Failed to decode saved locations: \(error.localizedDescription)")
            }
        }
    }
    
    
    func saveLocations() {
        if let encodedLocations = try? JSONEncoder().encode(locationData) {
            UserDefaults.standard.set(encodedLocations, forKey: "SavedLocations")
        }
    }
    
    func startUpdatingLocation() {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            print("Location updates cannot start - permission not granted")
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func deleteLocation(at index: Int) {
        locationData.remove(at: index)
        saveLocations()
    }
    func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied:
            print("Location access denied. Please enable it in settings.")
        case .restricted:
            print("Location access restricted.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            fatalError("Unhandled authorization status")
        }
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let country = placemarks?.first?.country,
               let countryCode = placemarks?.first?.isoCountryCode {
                DispatchQueue.main.async {
                    self.currentCountry = country
                    self.countryInfoService.fetchCountryInfo(countryCode: countryCode)
                }
            }
        }
    }
}

extension Notification.Name {
    static let didExitMonitoredRegion = Notification.Name("didExitMonitoredRegion")
    static let didEnterMonitoredRegion = Notification.Name("didEnterMonitoredRegion")
}
