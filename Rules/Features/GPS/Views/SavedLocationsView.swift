import SwiftUI
import CoreLocation
import MapKit

struct SavedLocationsView: View {
    var locationData: [LocationData]
    var deleteAction: (Int) -> Void
    
    @State private var selectedLocation: LocationData?
    @State private var showActionSheet = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "mountain"
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        ZStack {
            Image("\(selectedTheme)-bg\(isDarkMode ? "-dark" : "")")
                .resizable()
                .scaledToFill()
               // .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if locationData.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(Array(locationData.enumerated()), id: \.element.id) { index, location in
                            SavedLocationCard(location: location)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedLocation = location
                                        showActionSheet = true
                                    }
                                    HapticManager.shared.impact(style: .light)
                                }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("saved_locations".localized)
        .actionSheet(isPresented: $showActionSheet) {
            createActionSheet()
        }
    }
    
    private func createActionSheet() -> ActionSheet {
        ActionSheet(
            title: Text("location_actions".localized),
            message: Text(selectedLocation?.description ?? ""),
            buttons: [
                .default(Text("open_google_maps".localized)) {
                    openMapsApp(with: .googleMaps)
                    HapticManager.shared.impact(style: .medium)
                },
                .default(Text("open_apple_maps".localized)) {
                    openMapsApp(with: .appleMaps)
                    HapticManager.shared.impact(style: .medium)
                },
                .destructive(Text("delete".localized)) {
                    deleteSelectedLocation()
                    HapticManager.shared.notification(type: .success)
                },
                .cancel(Text("cancel".localized))
            ]
        )
    }
    
    private func deleteSelectedLocation() {
        if let index = locationData.firstIndex(where: { $0.id == selectedLocation?.id }) {
            withAnimation(.easeOut(duration: 0.3)) {
                deleteAction(index)
            }
        }
    }
    
    private func openMapsApp(with provider: MapProvider) {
        guard let location = selectedLocation,
              let url = URL(string: provider.urlString(latitude: location.latitude, longitude: location.longitude)),
              UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url)
    }
}

// MARK: - Subviews

struct SavedLocationCard: View {
    let location: LocationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatCoordinates(latitude: location.latitude, longitude: location.longitude))
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
            
            if !location.description.isEmpty {
                Text(location.description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(hex: "#29606D"))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private func formatCoordinates(latitude: Double, longitude: Double) -> String {
        let latDegrees = Int(latitude)
        let latMinutes = Int((latitude - Double(latDegrees)) * 60)
        let latSeconds = (latitude - Double(latDegrees) - Double(latMinutes) / 60) * 3600
        
        let lonDegrees = Int(longitude)
        let lonMinutes = Int((longitude - Double(lonDegrees)) * 60)
        let lonSeconds = (longitude - Double(lonDegrees) - Double(lonMinutes) / 60) * 3600
        
        let latDirection = latitude >= 0 ? "north".localized : "south".localized
        let lonDirection = longitude >= 0 ? "east".localized : "west".localized
        
        return String(format: "%d° %d' %.2f'' %@\n%d° %d' %.2f'' %@",
                     abs(latDegrees), abs(latMinutes), abs(latSeconds), latDirection,
                     abs(lonDegrees), abs(lonMinutes), abs(lonSeconds), lonDirection)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            Text("no_saved_locations".localized)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "#29606D").opacity(0.8))
        .cornerRadius(15)
    }
}

// MARK: - Preview
struct SavedLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SavedLocationsView(
                locationData: [
                    LocationData(latitude: 50.0, longitude: 20.0, description: "Test Location")
                ],
                deleteAction: { _ in }
            )
        }
    }
}
