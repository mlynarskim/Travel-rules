//  LocationManager.swift
import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentCountry: String = ""
    @Published var locationData: [LocationData] = []
    @Published var countryInfoService = CountryInfoService()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        loadSavedLocations()
    }
    
    private func loadSavedLocations() {
        if let savedData = UserDefaults.standard.data(forKey: "SavedLocations"),
           let decodedLocations = try? JSONDecoder().decode([LocationData].self, from: savedData) {
            locationData = decodedLocations
        }
    }
    
    func saveLocations() {
        if let encodedLocations = try? JSONEncoder().encode(locationData) {
            UserDefaults.standard.set(encodedLocations, forKey: "SavedLocations")
        }
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func deleteLocation(at index: Int) {
        locationData.remove(at: index)
        saveLocations()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        reverseGeocode(location: location)
    }
    
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
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
