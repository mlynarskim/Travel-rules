// SavedLocationsView.swift
import SwiftUI
import CoreLocation
import MapKit

struct SavedLocationsView: View {
    @Binding var locationData: [LocationData]
    var deleteAction: (Int) -> Void
    
    @State private var selectedLocation: LocationData?
    @State private var showActionSheet = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"
    @StateObject private var languageManager = LanguageManager.shared
    
    // MARK: - Background Image
    private var backgroundImageView: some View {
        let imageName: String
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:   imageName = isDarkMode ? "classic-bg-dark" : "theme-classic-preview"
        case .mountain:  imageName = isDarkMode ? "mountain-bg-dark" : "theme-mountain-preview"
        case .beach:     imageName = isDarkMode ? "beach-bg-dark" : "theme-beach-preview"
        case .desert:    imageName = isDarkMode ? "desert-bg-dark" : "theme-desert-preview"
        case .forest:    imageName = isDarkMode ? "forest-bg-dark" : "theme-forest-preview"
        }
        return Image(imageName)
            .resizable()
            .scaledToFill()
    }
    
    var body: some View {
        ZStack {
            backgroundImageView
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
              .navigationBarBackButtonHidden(true)

                .padding(.horizontal)
                .padding(.top, 60)
                .padding(.bottom, 20)
            }
        }

        .confirmationDialog("location_actions".localized, isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("open_google_maps".localized) {
                openMapsApp(with: .googleMaps)
                HapticManager.shared.impact(style: .medium)
            }
            Button("open_apple_maps".localized) {
                openMapsApp(with: .appleMaps)
                HapticManager.shared.impact(style: .medium)
            }
            Button("delete".localized, role: .destructive) {
                deleteSelectedLocation()
                HapticManager.shared.notification(type: .success)
            }
            Button("cancel".localized, role: .cancel) {}
        } message: {
            Text(selectedLocation?.description ?? "")
        }
    }
    
    private func deleteSelectedLocation() {
        if let index = locationData.firstIndex(where: { $0.id == selectedLocation?.id }) {
            withAnimation(.easeOut(duration: 0.3)) {
                deleteAction(index)
                selectedLocation = nil
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
        VStack(spacing: 8) {
            // Nazwa lokalizacji z pinezką w kolorze markerColor
            if !location.description.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(colorForMarker(location.markerColor))
                        .frame(width: 10, height: 10)
                    Text(location.description)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            // Współrzędne w jednej linii
            Text(formatCoordinates(latitude: location.latitude, longitude: location.longitude))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
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
        
        return String(format: "%d° %d' %.2f'' %@, %d° %d' %.2f'' %@",
                      abs(latDegrees), abs(latMinutes), abs(latSeconds), latDirection,
                      abs(lonDegrees), abs(lonMinutes), abs(lonSeconds), lonDirection)
    }
    
    private func colorForMarker(_ marker: String) -> Color {
        switch marker {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        default: return .red
        }
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
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "#29606D").opacity(0.8))
        .cornerRadius(15)

    }
}

// MARK: - Preview Container

struct SavedLocationsViewPreviewContainer: View {
    @State private var previewLocations: [LocationData] = [
        LocationData(latitude: 50.0, longitude: 20.0, description: "Test Location", markerColor: "red")
    ]
    
    var body: some View {
        NavigationView {
            SavedLocationsView(locationData: $previewLocations, deleteAction: { index in
                previewLocations.remove(at: index)
            })
        }
    }
}

