// Features/People/Views/PeopleMapView.swift
import SwiftUI
import MapKit

struct PeopleMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.237049, longitude: 21.017532),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .edgesIgnoringSafeArea(.all)
            
            if !locationManager.currentCountry.isEmpty {
                Text("Kraj: \(locationManager.currentCountry)")
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
    }
}

struct PeopleMapView_Previews: PreviewProvider {
    static var previews: some View {
        PeopleMapView()
    }
}
