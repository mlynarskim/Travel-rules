import SwiftUI
import Foundation
import CoreLocation
import MapKit

struct LocationData: Identifiable, Codable {
    var id = UUID()
    let latitude: Double
    let longitude: Double
    var description: String
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationData: [LocationData] = []

    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Wczytaj zapisane lokalizacje przy starcie
        if let savedData = UserDefaults.standard.data(forKey: "SavedLocations") {
            let decoder = JSONDecoder()
            if let decodedLocations = try? decoder.decode([LocationData].self, from: savedData) {
                locationData = decodedLocations
            }
        }
    }
    
    func saveLocations() {
        let encoder = JSONEncoder()
        if let encodedLocations = try? encoder.encode(locationData) {
            UserDefaults.standard.set(encodedLocations, forKey: "SavedLocations")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if let lastLocationData = locationData.last, lastLocationData.description.isEmpty {
            // Jeśli ostatnia lokalizacja nie ma opisu, zaktualizuj ją z nową lokalizacją
            locationData[locationData.count - 1] = LocationData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, description: "")
        } else {
            // W przeciwnym razie, dodaj nową lokalizację
            let newLocation = LocationData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, description: "")
            locationData.append(newLocation)
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
}

struct GPSView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var description = ""
    @State private var currentLocation: CLLocation?
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                VStack {
                    Text("Current Location:")
                        .font(.headline)
                    
                    if let location = currentLocation {
                        Text("Latitude: \(location.coordinate.latitude)")
                        Text("Longitude: \(location.coordinate.longitude)")
                    } else {
                        Text("Waiting for location...")
                    }
                }
                Spacer()
                Spacer()
                
                VStack {
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    HStack {
                        Button(action: {
                            guard let location = currentLocation else { return }
                            if !description.isEmpty {
                                let newLocation = LocationData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, description: description)
                                locationManager.locationData.append(newLocation)
                                description = "" // Clear the description field
                                print("Save button tapped")
                                locationManager.saveLocations()
                            }
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 120, height: 50)
                                .background(Color(hex: "#29606D"))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .padding()
                        }
                        NavigationLink(destination: SavedLocationsView(locationData: locationManager.locationData, deleteAction: locationManager.deleteLocation)) {
                            Text("Locations")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 120, height: 50)
                                .background(Color(hex: "#29606D"))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .padding()
                        }
                    }
                }
                .frame(width: 340)
                .background(Color.white.opacity(0.7))
                .cornerRadius(15)
                
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            locationManager.startUpdatingLocation()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            locationManager.stopUpdatingLocation()
        }
        .onReceive(locationManager.$locationData) { locations in
            if let lastLocation = locations.last {
                currentLocation = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
            }
        }
    }
}




struct GPSView_Previews: PreviewProvider {
    static var previews: some View {
        GPSView()
    }
}
