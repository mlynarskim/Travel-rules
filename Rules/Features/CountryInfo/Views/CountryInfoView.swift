import SwiftUI

struct CountryInfoView: View {
    let countryInfo: CountryInfo
    @AppStorage("isDarkMode") var isDarkMode = false
    
    var body: some View {
        ZStack {
            Image(isDarkMode ? "imageDark" : "Image")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            List {
                Section(header: Text("Emergency Numbers")
                    .foregroundColor(.white)) {
                        Text("General: \(countryInfo.emergencyNumbers.general)")
                            .foregroundColor(.white)
                        Text("Police: \(countryInfo.emergencyNumbers.police)")
                            .foregroundColor(.white)
                        Text("Ambulance: \(countryInfo.emergencyNumbers.ambulance)")
                            .foregroundColor(.white)
                        Text("Fire: \(countryInfo.emergencyNumbers.fire)")
                            .foregroundColor(.white)
                }
                .listRowBackground(Color(hex: "#29606D").opacity(0.8))
                
                Section(header: Text("Useful Links")
                    .foregroundColor(.white)) {
                    ForEach(countryInfo.usefulLinks, id: \.url) { link in
                        Link(link.title, destination: URL(string: link.url)!)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color(hex: "#29606D").opacity(0.8))
                
                if let embassyInfo = countryInfo.embassyInfo {
                    Section(header: Text("Embassy Information")
                        .foregroundColor(.white)) {
                        Text(embassyInfo)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(hex: "#29606D").opacity(0.8))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.clear)
            .navigationTitle("Country Information")
        }
    }
}
