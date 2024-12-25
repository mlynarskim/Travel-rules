import SwiftUI
import Foundation
import CoreLocation
import MapKit

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
            locationData[locationData.count - 1] = LocationData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, description: "")
        } else {
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
    @State private var region = MKCoordinateRegion()
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
                
                // Mapa z kompatybilnością wsteczną
                if #available(iOS 17.0, *) {
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 240)
                        .frame(width: 340)
                        .cornerRadius(15)
                        .padding(.horizontal)
                } else {
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 240)
                        .frame(width: 340)
                        .cornerRadius(15)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                VStack {
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    HStack {
                        Button(action: {
                            guard let location = currentLocation else { return }
                            if !description.isEmpty {
                                let newLocation = LocationData(
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude,
                                    description: description
                                )
                                locationManager.locationData.append(newLocation)
                                description = ""
                                locationManager.saveLocations()
                            }
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
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
                .padding(.bottom, 20)
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
                let coordinate = CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        }
    }
}

struct SavedLocationsView: View {
    var locationData: [LocationData]
    var deleteAction: (Int) -> Void
    
    @State private var selectedLocation: LocationData?
    @State private var showActionSheet = false
    @AppStorage("isDarkMode") var isDarkMode = false
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(locationData.enumerated()), id: \.element.id) { index, location in
                        VStack {
                            Text(formatCoordinates(latitude: location.latitude, longitude: location.longitude))
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Description: \(location.description)")
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: 340, height: 80)
                        .background(Color(hex: "#29606D"))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            selectedLocation = location
                            showActionSheet = true
                        }
                    }
                }
                .padding()
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Location Actions"), buttons: [
                .default(Text("Open in Google Maps")) {
                    openMapsApp(with: .googleMaps, location: selectedLocation)
                },
                .default(Text("Open in Apple Maps")) {
                    openMapsApp(with: .appleMaps, location: selectedLocation)
                },
                .destructive(Text("Delete")) {
                    if let index = locationData.firstIndex(where: { $0.id == selectedLocation?.id }) {
                        deleteAction(index)
                    }
                },
                .cancel()
            ])
        }
    }
    
    private func formatCoordinates(latitude: Double, longitude: Double) -> String {
        let latDegrees = Int(latitude)
        let latMinutes = Int((latitude - Double(latDegrees)) * 60)
        let latSeconds = (latitude - Double(latDegrees) - Double(latMinutes) / 60) * 3600
        
        let lonDegrees = Int(longitude)
        let lonMinutes = Int((longitude - Double(lonDegrees)) * 60)
        let lonSeconds = (longitude - Double(lonDegrees) - Double(lonMinutes) / 60) * 3600
        
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"
        
        return String(format: "%d° %d' %.3f'' %@\n%d° %d' %.4f'' %@",
                     abs(latDegrees), abs(latMinutes), abs(latSeconds), latDirection,
                     abs(lonDegrees), abs(lonMinutes), abs(lonSeconds), lonDirection)
    }
    
    private func openMapsApp(with provider: MapProvider, location: LocationData?) {
        guard let location = location else { return }
        
        let urlString = provider.urlString(latitude: location.latitude, longitude: location.longitude)
        guard let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

struct GPSView_Previews: PreviewProvider {
    static var previews: some View {
        GPSView()
    }
}
