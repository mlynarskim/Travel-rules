import SwiftUI
import Foundation
import CoreLocation
import MapKit

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
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)
                Spacer()
                HStack {
                    ScrollView {
                        Spacer()
                        ForEach(locationData) { location in
                            VStack {
                                Text(formatCoordinates(latitude: location.latitude, longitude: location.longitude))
                                    .foregroundColor(Color.white)
                                    .padding(.vertical, 5)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("Description: \(location.description)")
                                    .foregroundColor(Color.white)
                                    .padding(.bottom, 5)
                                    .fixedSize(horizontal: false, vertical: true)

                            }
                            .frame(width: 340, height: 80.0)
                            .background(Color(hex: "#29606D"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            .onTapGesture {
                                selectedLocation = location
                                showActionSheet = true
                            }
                        }
                        .onDelete(perform: deleteLocation)
                    }
                    .listStyle(PlainListStyle())
                    .padding(20)
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



//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
