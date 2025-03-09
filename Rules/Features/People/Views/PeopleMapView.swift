import SwiftUI
import MapKit
import CoreLocation

struct PeopleMapView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var peopleService = PeopleLocationService.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.237049, longitude: 21.017532),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var selectedVisibilityRadius: Double = 5.0
    @State private var showingFilters = false
    @State private var showStats = false
    @State private var showOnlyAvailable = false
    @State private var showingCheckInSheet = false
    
    private let visibilityOptions: [Double] = [5.0, 10.0, 15.0]
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: peopleService.nearbyUsers) { user in
                MapAnnotation(coordinate: user.location) {
                    UserAnnotationView(user: user)
                }
            }
            //.edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
            VStack {
                Spacer()
                
                // Panel informacyjny
                if showStats {
                    statsView
                }
                
                // Przyciski kontrolne
                controlButtons
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(showOnlyAvailable: $showOnlyAvailable)
        }
        .sheet(isPresented: $showingCheckInSheet) {
            CheckInView(isPresented: $showingCheckInSheet)
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            peopleService.refreshData()
        }
    }
    
    private var statsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Osoby w pobliżu: \(peopleService.nearbyUsers.count)")
            if let closest = peopleService.nearbyUsers.first {
                Text("Najbliższa osoba: \(String(format: "%.1f", closest.distance)) km")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding()
    }
    
    private var controlButtons: some View {
        HStack {
            controlButton(icon: "line.3.horizontal.decrease.circle.fill", action: { showingFilters.toggle() })
            
            Spacer()
            
            if peopleService.isCheckedIn {
                controlButton(icon: "mappin.slash.circle.fill", action: peopleService.checkOut)
            } else {
                controlButton(icon: "mappin.circle.fill", action: { showingCheckInSheet.toggle() })
            }
            
            Spacer()
            
            controlButton(icon: "arrow.clockwise.circle.fill", action: peopleService.refreshData)
            
            Spacer()
            
            controlButton(icon: showStats ? "chart.bar.fill" : "chart.bar", action: { showStats.toggle() })
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}

struct UserAnnotationView: View {
    let user: NearbyUser
    @State private var showingDetails = false
    @State private var isShowingInfo = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(user.shareLevel == .exact ? Color.blue.opacity(0.6) : Color.gray.opacity(0.4),
                        lineWidth: 1)
                .frame(width: CGFloat(user.shareLevel.radiusInMeters) / 100,
                       height: CGFloat(user.shareLevel.radiusInMeters) / 100)
            
            Button(action: { showingDetails.toggle() }) {
                VStack(spacing: 4) {
                    if isShowingInfo {
                        Text(user.name)
                            .font(.caption)
                            .padding(4)
                            .background(Color(.systemBackground))
                            .cornerRadius(4)
                            .shadow(radius: 1)
                    }
                    
                    Image(systemName: user.category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(categoryColor)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .onTapGesture {
                withAnimation {
                    isShowingInfo.toggle()
                }
            }
        }
        .sheet(isPresented: $showingDetails) {
            // Jeśli UserProfileView nie przyjmuje argumentów, wywołaj bez parametrów.
            // Jeśli chcesz przekazywać 'user', musisz dodać odpowiedni inicjalizator w UserProfileView.
            UserProfileView()
        }
    }
    
    private var categoryColor: Color {
        switch user.category {
        case .social: return .blue
        case .help: return .green
        case .family: return .orange
        @unknown default: return .gray
        }
    }
}

struct CheckInView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var peopleService = PeopleLocationService.shared
    @State private var selectedDuration: TimeInterval = 3600
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Czas zameldowania")) {
                    Picker("Czas", selection: $selectedDuration) {
                        Text("1 godzina").tag(TimeInterval(3600))
                        Text("3 godziny").tag(TimeInterval(10800))
                        Text("6 godzin").tag(TimeInterval(21600))
                        Text("12 godzin").tag(TimeInterval(43200))
                        Text("24 godziny").tag(TimeInterval(86400))
                    }
                }
                
                Button("Zamelduj się") {
                    if let location = peopleService.currentLocation?.coordinate {
                        peopleService.checkIn(at: location, duration: selectedDuration)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Zameldowanie")
            .navigationBarItems(trailing: Button("Anuluj") {
                isPresented = false
            })
        }
    }
}
