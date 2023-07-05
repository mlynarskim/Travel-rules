
//  Created by Mateusz Mlynarski
//
import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Foundation


struct SavedLocationsView: View {
    var locationData: [LocationData]
    var deleteAction: (Int) -> Void
    
    @State private var selectedLocation: LocationData?
    @State private var showActionSheet = false
    @AppStorage("isDarkMode") var isDarkMode = false

    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)

                
                List {
                    ForEach(locationData) { location in
                        VStack(alignment: .leading) {
                            Text(formatCoordinates(latitude: location.latitude, longitude: location.longitude))
                                .foregroundColor(Color.black)
                                .padding(.vertical, 5)
                            Text("Description: \(location.description)")
                                .foregroundColor(Color.gray)
                                .padding(.bottom, 5)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.vertical, 5)
                        .onTapGesture {
                            selectedLocation = location
                            showActionSheet = true
                        }
                    }
                    .onDelete(perform: deleteLocation)
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Saved Locations")
                .foregroundColor(.black)
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Open in Maps"), buttons: [
                .default(Text("Google Maps")) {
                    openMapsApp(with: .googleMaps, location: selectedLocation)
                },
                .default(Text("Apple Maps")) {
                    openMapsApp(with: .appleMaps, location: selectedLocation)
                },
                .cancel()
            ])
        }
    }
    
    private func deleteLocation(at offsets: IndexSet) {
        for index in offsets {
            deleteAction(index)
        }
    }
    
    private func openMapsApp(with provider: MapProvider, location: LocationData?) {
        guard let location = location else { return }
        
        let urlString = provider.urlString(latitude: location.latitude, longitude: location.longitude)
        guard let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Handle error or show alternative navigation option
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
        
        return String(format: "%d° %d' %.3f'' \(latDirection)\n%d° %d' %.4f'' \(lonDirection)", abs(latDegrees), abs(latMinutes), abs(latSeconds), abs(lonDegrees), abs(lonMinutes), abs(lonSeconds))
    }
}


enum MapProvider {
    case googleMaps
    case appleMaps
    
    func urlString(latitude: Double, longitude: Double) -> String {
        switch self {
        case .googleMaps:
            return "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)&zoom=14"
        case .appleMaps:
            return "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(latitude),\(longitude)&z=14"
        }
    }
}
