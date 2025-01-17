import SwiftUI
import CoreLocation
import MapKit

struct GPSView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var description = ""
    @State private var currentLocation: CLLocation?
    @State private var region = MKCoordinateRegion()
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @StateObject private var languageManager = LanguageManager.shared
    @State private var isCountryInfoExpanded = false
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isSmallDevice ? 12 : 16) {
                        CurrentLocationCard(
                            currentLocation: currentLocation,
                            themeColors: themeColors,
                            isSmallDevice: isSmallDevice
                        )
                        .transition(AnyTransition.scale)
                        
                        // Map
                        if #available(iOS 14.0, *) {
                            Map(coordinateRegion: $region, showsUserLocation: true)
                                .frame(height: isSmallDevice ? 150 : 200)
                                .frame(maxWidth: isSmallDevice ? 300 : 340)
                                .cornerRadius(15)
                                .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                        } else {
                            MapFallbackView(region: $region)
                                .frame(height: isSmallDevice ? 150 : 200)
                                .frame(maxWidth: isSmallDevice ? 300 : 340)
                                .cornerRadius(15)
                                .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                        }
                        
                        if !locationManager.currentCountry.isEmpty {
                            CountryInfoCard(
                                countryName: locationManager.currentCountry,
                                isExpanded: $isCountryInfoExpanded,
                                countryInfo: locationManager.countryInfoService.countryInfo,
                                themeColors: themeColors,
                                isSmallDevice: isSmallDevice
                            )
                        }
                        
                        LocationInputPanel(
                            description: $description,
                            currentLocation: currentLocation,
                            locationManager: locationManager,
                            themeColors: themeColors,
                            isSmallDevice: isSmallDevice
                        )
                    }
                    .padding(.top, isSmallDevice ? 8 : 16)
                    .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation {
                locationManager.startUpdatingLocation()
            }
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onReceive(locationManager.$locationData) { locations in
            if let lastLocation = locations.last {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentLocation = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                }
            }
        }
    }
}

struct MapFallbackView: View {
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        Text("map_not_available".appLocalized)
            .font(.system(size: 16))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
    }
}
struct CurrentLocationCard: View {
    let currentLocation: CLLocation?
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    
    var body: some View {
        VStack(spacing: isSmallDevice ? 8 : 10) {
            Text("current_location".appLocalized)
                .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                .foregroundColor(.white)
            
            if let location = currentLocation {
                VStack(spacing: isSmallDevice ? 4 : 5) {
                    Text("\("latitude".appLocalized): \(String(format: "%.6f", location.coordinate.latitude))")
                        .font(.system(size: isSmallDevice ? 14 : 16))
                    Text("\("longitude".appLocalized): \(String(format: "%.6f", location.coordinate.longitude))")
                        .font(.system(size: isSmallDevice ? 14 : 16))
                }
                .foregroundColor(.white)
            } else {
                Text("waiting_location".appLocalized)
                    .font(.system(size: isSmallDevice ? 14 : 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: isSmallDevice ? 300 : 340)
        .padding(isSmallDevice ? 12 : 16)
        .background(themeColors.primary)
        .cornerRadius(15)
        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
    }
}

struct CountryInfoCard: View {
    let countryName: String
    @Binding var isExpanded: Bool
    let countryInfo: CountryInfo?
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    
    var body: some View {
        VStack(spacing: isSmallDevice ? 8 : 10) {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
                HapticManager.shared.impact(style: .light)
            }) {
                HStack {
                    Text(countryName.isEmpty ? "waiting_for_country".appLocalized : "country_location".appLocalized + countryName)
                        .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(), value: isExpanded)
                }
                .padding(isSmallDevice ? 12 : 16)
                .frame(maxWidth: isSmallDevice ? 300 : 340)
                .background(themeColors.primary)
                .cornerRadius(15)
            }
            
            if isExpanded, let info = countryInfo {
                CountryInfoDetails(
                    info: info,
                    themeColors: themeColors,
                    isSmallDevice: isSmallDevice
                )
                .transition(AnyTransition.scale.combined(with: .opacity))
            }
        }
    }
}

struct CountryInfoDetails: View {
    let info: CountryInfo
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isSmallDevice ? 12 : 15) {
            VStack(alignment: .leading, spacing: isSmallDevice ? 6 : 8) {
                Text("emergency_numbers".appLocalized)
                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                    .foregroundColor(.white)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: isSmallDevice ? 6 : 8) {
                    GridRow {
                        Text("📞 \("general".appLocalized): \(info.emergencyNumbers.general)")
                        Text("👮 \("police".appLocalized): \(info.emergencyNumbers.police)")
                    }
                    GridRow {
                        Text("🚑 \("ambulance".appLocalized): \(info.emergencyNumbers.ambulance)")
                        Text("🚒 \("fire".appLocalized): \(info.emergencyNumbers.fire)")
                    }
                }
                .font(.system(size: isSmallDevice ? 14 : 16))
                .foregroundColor(.white)
            }
            
            if !info.usefulLinks.isEmpty {
                Divider().background(Color.white)
                
                VStack(alignment: .leading, spacing: isSmallDevice ? 6 : 8) {
                    Text("useful_links".appLocalized)
                        .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                        .foregroundColor(.white)
                    ForEach(info.usefulLinks, id: \.url) { link in
                        Link(destination: URL(string: link.url)!) {
                            Text("🔗 \(link.title)")
                                .underline()
                                .foregroundColor(.white)
                                .font(.system(size: isSmallDevice ? 14 : 16))
                        }
                    }
                }
            }
            
            if let embassy = info.embassyInfo {
                Divider().background(Color.white)
                Text("embassy_information".appLocalized)
                    .font(.system(size: isSmallDevice ? 16 : 18, weight: .bold))
                    .foregroundColor(.white)
                Text("🏛 \(embassy)")
                    .font(.system(size: isSmallDevice ? 14 : 16))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: isSmallDevice ? 300 : 340)
        .padding(isSmallDevice ? 12 : 16)
        .background(themeColors.primary)
        .cornerRadius(15)
    }
}

struct LocationInputPanel: View {
    @Binding var description: String
    let currentLocation: CLLocation?
    let locationManager: LocationManager
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    
    var body: some View {
        VStack(spacing: isSmallDevice ? 12 : 15) {
            TextField("description".appLocalized, text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: isSmallDevice ? 14 : 16))
                .padding(.horizontal)
            
            HStack(spacing: isSmallDevice ? 16 : 20) {
                Button(action: saveLocation) {
                    Text("save_location".appLocalized)
                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: isSmallDevice ? 100 : 120, height: isSmallDevice ? 36 : 44)
                        .background(themeColors.primary)
                        .cornerRadius(15)
                        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                }
                
                NavigationLink(
                    destination: SavedLocationsView(
                        locationData: locationManager.locationData,
                        deleteAction: locationManager.deleteLocation
                    )
                ) {
                    Text("locations".appLocalized)
                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: isSmallDevice ? 100 : 120, height: isSmallDevice ? 36 : 44)
                        .background(themeColors.primary)
                        .cornerRadius(15)
                        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                }
            }
        }
        .frame(maxWidth: isSmallDevice ? 300 : 340)
        .padding(isSmallDevice ? 12 : 16)
        .background(themeColors.cardBackground)
        .cornerRadius(15)
    }
    
    private func saveLocation() {
        guard let location = currentLocation, !description.isEmpty else { return }
        
        withAnimation(.spring()) {
            let newLocation = LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                description: description
            )
            locationManager.locationData.append(newLocation)
            description = ""
            locationManager.saveLocations()
            HapticManager.shared.impact(style: .medium)
        }
    }
}

struct GPSView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GPSView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE")
            
            GPSView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
                .previewDisplayName("iPhone 14 Pro Max")
                .environment(\.colorScheme, .dark)
        }
    }
}
