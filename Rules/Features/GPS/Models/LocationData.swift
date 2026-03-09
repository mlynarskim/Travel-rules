import Foundation
import CoreLocation

struct LocationData: Identifiable, Codable {
    var id = UUID() 
    var latitude: Double
    var longitude: Double
    var description: String
    var markerColor: String = "red"
}

enum MapProvider {
    case googleMaps
    case appleMaps
    
    func urlString(latitude: Double, longitude: Double) -> String {
        switch self {
        case .googleMaps:
            return "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)"
        case .appleMaps:
            return "http://maps.apple.com/?ll=\(latitude),\(longitude)"
        }
    }
}

