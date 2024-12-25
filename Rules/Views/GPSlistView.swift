import SwiftUI
import CoreLocation
import MapKit
import Foundation


struct LocationInfoView: View {
    let location: CLLocation
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Current Location")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 340, height: 40)
                .background(Color(hex: "#29606D"))
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 10) {
                CoordinateRow(
                    title: "Latitude",
                    value: location.coordinate.latitude,
                    format: "%.6f°"
                )
                
                CoordinateRow(
                    title: "Longitude",
                    value: location.coordinate.longitude,
                    format: "%.6f°"
                )
                
                if location.altitude != 0 {
                    CoordinateRow(
                        title: "Altitude",
                        value: location.altitude,
                        format: "%.1f m"
                    )
                }
            }
            .padding()
            .frame(width: 340)
            .background(Color.white)
            .cornerRadius(15)
        }
    }
}

// Pojedynczy wiersz z współrzędną
struct CoordinateRow: View {
    let title: String
    let value: Double
    let format: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.black)
                .font(.headline)
            Spacer()
            Text(String(format: format, value))
                .foregroundColor(.black)
                .font(.body)
        }
    }
}

// Przyciski akcji
struct ActionButtons: View {
    let getCurrentLocation: () -> Void
    let saveLocation: () -> Void
    let showSavedLocations: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Button(action: getCurrentLocation) {
                ActionButtonLabel(
                    title: "Get Location",
                    systemImage: "location"
                )
            }
            
            Button(action: saveLocation) {
                ActionButtonLabel(
                    title: "Save Location",
                    systemImage: "pin"
                )
            }
            
            Button(action: showSavedLocations) {
                ActionButtonLabel(
                    title: "Saved Locations",
                    systemImage: "list.star"
                )
            }
        }
    }
}

struct ActionButtonLabel: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 20))
            Text(title)
                .font(.custom("Lato Bold", size: 20))
        }
        .foregroundColor(.white)
        .frame(width: 340, height: 50)
        .background(Color(hex: "#29606D"))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// Arkusz do wprowadzania opisu lokalizacji
struct LocationInputSheet: View {
    let location: CLLocation?
    @Binding var description: String
    @Binding var savedLocations: [LocationData]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#DDAA4F")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if let location = location {
                        Text("Location Details")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $description)
                            .frame(height: 150)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        Text("Enter location description...")
                                            .foregroundColor(.gray)
                                            .padding()
                                    }
                                }
                            )
                        
                        Button("Save Location") {
                            saveLocation(location)
                        }
                        .font(.custom("Lato Bold", size: 20))
                        .foregroundColor(.white)
                        .frame(width: 340, height: 50)
                        .background(Color(hex: "#29606D"))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    } else {
                        Text("Location not available")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveLocation(_ location: CLLocation) {
        let newLocation = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            description: description
        )
        savedLocations.append(newLocation)
        presentationMode.wrappedValue.dismiss()
        description = ""
    }
}

// Alert dla błędów lokalizacji
struct LocationErrorAlert: View {
    let error: Error
    let dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Location Error")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.body)
            Button("OK", action: dismissAction)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}
