import Foundation
import CoreLocation

struct NearbyPerson: Identifiable, Codable {
    let id: UUID
    var name: String
    var location: LocationData
    var distance: Double?
    
    init(id: UUID = UUID(), name: String, location: LocationData) {
        self.id = id
        self.name = name
        self.location = location
    }
}
