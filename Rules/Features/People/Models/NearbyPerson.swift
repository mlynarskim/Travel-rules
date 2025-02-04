//NearbyUser.swift
import Foundation
import CoreLocation

public struct NearbyUser: Identifiable, Codable {
   public let id: UUID
   public var name: String
   public var status: UserStatus
   public var category: UserCategory
   public var location: CLLocationCoordinate2D
   public var distance: Double
   public var shareLevel: LocationShareLevel
   public var description: String?
   public var helpOffered: [HelpType]
   public var lastActiveTime: Date
   public var automaticCheckIn: Bool
   
   // Nowe pola dla statystyk
   public var helpProvidedCount: Int?
   public var activeDaysCount: Int?
   public var thanksReceivedCount: Int?
   
   public init(
       id: UUID,
       name: String,
       status: UserStatus,
       category: UserCategory,
       location: CLLocationCoordinate2D,
       distance: Double,
       shareLevel: LocationShareLevel,
       description: String?,
       helpOffered: [HelpType] = [],
       lastActiveTime: Date = Date(),
       automaticCheckIn: Bool = false,
       helpProvidedCount: Int? = nil,
       activeDaysCount: Int? = nil,
       thanksReceivedCount: Int? = nil
   ) {
       self.id = id
       self.name = name
       self.status = status
       self.category = category
       self.location = location
       self.distance = distance
       self.shareLevel = shareLevel
       self.description = description
       self.helpOffered = helpOffered
       self.lastActiveTime = lastActiveTime
       self.automaticCheckIn = automaticCheckIn
       self.helpProvidedCount = helpProvidedCount
       self.activeDaysCount = activeDaysCount
       self.thanksReceivedCount = thanksReceivedCount
   }
   
   public enum UserStatus: String, Codable {
       case available
       case busy
       case needsHelp
       case offering
       case temporary
       
       public var localizedName: String {
           switch self {
           case .available:
               return NSLocalizedString("Dostępny", comment: "")
           case .busy:
               return NSLocalizedString("Zajęty", comment: "")
           case .needsHelp:
               return NSLocalizedString("Potrzebuje pomocy", comment: "")
           case .offering:
               return NSLocalizedString("Oferuje pomoc", comment: "")
           case .temporary:
               return NSLocalizedString("Tymczasowo", comment: "")
           }
       }
       
       public var icon: String {
           switch self {
           case .available: return "checkmark.circle.fill"
           case .busy: return "minus.circle.fill"
           case .needsHelp: return "exclamationmark.circle.fill"
           case .offering: return "hand.raised.fill"
           case .temporary: return "clock.fill"
           }
       }
   }
   
   public enum UserCategory: String, Codable {
       case social
       case help
       case family
       case camping
       case vanlife
       case technical
       case childcare
       
       public var localizedName: String {
           switch self {
           case .social:
               return NSLocalizedString("Towarzysko", comment: "")
           case .help:
               return NSLocalizedString("Pomoc", comment: "")
           case .family:
               return NSLocalizedString("Rodzina", comment: "")
           case .camping:
               return NSLocalizedString("Kemping", comment: "")
           case .vanlife:
               return NSLocalizedString("Van Life", comment: "")
           case .technical:
               return NSLocalizedString("Pomoc techniczna", comment: "")
           case .childcare:
               return NSLocalizedString("Opieka nad dziećmi", comment: "")
           }
       }
       
       public var icon: String {
           switch self {
           case .social: return "person.2.fill"
           case .help: return "wrench.fill"
           case .family: return "house.fill"
           case .camping: return "tent.fill"
           case .vanlife: return "car.fill"
           case .technical: return "screwdriver.fill"
           case .childcare: return "figure.and.child.holdinghands"
           }
       }
   }
   
    public enum LocationShareLevel: String, Codable {
       case exact
       case approximate
       case hidden
       case radius1km
       
       public var radius: Double {
           switch self {
           case .exact: return 0.0
           case .approximate: return 500.0 // 500m radius
           case .hidden: return 2000.0 // 2km radius
           case .radius1km: return 1000.0 // 1km radius
           }
       }
       
       public var radiusInMeters: Double {
           radius
       }
       
       public var localizedName: String {
           switch self {
           case .exact:
               return NSLocalizedString("Dokładna lokalizacja", comment: "")
           case .approximate:
               return NSLocalizedString("Przybliżona lokalizacja", comment: "")
           case .hidden:
               return NSLocalizedString("Ukryta lokalizacja", comment: "")
           case .radius1km:
               return NSLocalizedString("Promień 1 km", comment: "")
           }
       }
    }
   
   public enum HelpType: String, Codable {
       case technical
       case tools
       case transport
       case social
       case resources
       case childcare
       
       public var localizedName: String {
           switch self {
           case .technical:
               return NSLocalizedString("Pomoc techniczna", comment: "")
           case .tools:
               return NSLocalizedString("Narzędzia", comment: "")
           case .transport:
               return NSLocalizedString("Transport/holowanie", comment: "")
           case .social:
               return NSLocalizedString("Towarzystwo", comment: "")
           case .resources:
               return NSLocalizedString("Dzielenie się zasobami", comment: "")
           case .childcare:
               return NSLocalizedString("Opieka nad dziećmi", comment: "")
           }
       }
       
       public var icon: String {
           switch self {
           case .technical: return "wrench.fill"
           case .tools: return "hammer.fill"
           case .transport: return "car.fill"
           case .social: return "person.2.fill"
           case .resources: return "box.truck.fill"
           case .childcare: return "figure.and.child.holdinghands"
           }
       }
   }
}

extension CLLocationCoordinate2D: Codable {
   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       try container.encode(latitude, forKey: .latitude)
       try container.encode(longitude, forKey: .longitude)
   }
   
   public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       let latitude = try container.decode(Double.self, forKey: .latitude)
       let longitude = try container.decode(Double.self, forKey: .longitude)
       self.init(latitude: latitude, longitude: longitude)
   }
   
   private enum CodingKeys: String, CodingKey {
       case latitude
       case longitude
   }
}
