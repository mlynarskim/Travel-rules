//UserProfile.swift
import Foundation

public struct UserProfile: Codable {
    public let id: UUID
    public var name: String
    public var description: String?
    public var category: UserCategory
    public var status: UserStatus
    public var shareLevel: LocationShareLevel
    public var helpOffered: [HelpType]
    public var preferences: UserPreferences
    
    // Dodajemy inicjalizator
    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        category: UserCategory,
        status: UserStatus,
        shareLevel: LocationShareLevel,
        helpOffered: [HelpType] = [],
        preferences: UserPreferences
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.status = status
        self.shareLevel = shareLevel
        self.helpOffered = helpOffered
        self.preferences = preferences
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
            case .technical: return NSLocalizedString("Pomoc techniczna", comment: "")
            case .tools: return NSLocalizedString("Narzędzia", comment: "")
            case .transport: return NSLocalizedString("Transport/holowanie", comment: "")
            case .social: return NSLocalizedString("Towarzystwo", comment: "")
            case .resources: return NSLocalizedString("Dzielenie się zasobami", comment: "")
            case .childcare: return NSLocalizedString("Opieka nad dziećmi", comment: "")
            }
        }
    }
    
    public struct UserPreferences: Codable {
        public var visibleToGroups: [String]
        public var automaticCheckin: Bool
        public var checkinRadius: Double
        public var notificationPreferences: NotificationPreferences
        
        // Dodajemy inicjalizator dla UserPreferences
        public init(
            visibleToGroups: [String] = [],
            automaticCheckin: Bool = false,
            checkinRadius: Double = 5.0,
            notificationPreferences: NotificationPreferences = NotificationPreferences()
        ) {
            self.visibleToGroups = visibleToGroups
            self.automaticCheckin = automaticCheckin
            self.checkinRadius = checkinRadius
            self.notificationPreferences = notificationPreferences
        }
        
        public struct NotificationPreferences: Codable {
            public var newNearbyUsers: Bool
            public var messages: Bool
            public var locationRequests: Bool
            
            // Dodajemy inicjalizator dla NotificationPreferences
            public init(
                newNearbyUsers: Bool = true,
                messages: Bool = true,
                locationRequests: Bool = true
            ) {
                self.newNearbyUsers = newNearbyUsers
                self.messages = messages
                self.locationRequests = locationRequests
            }
        }
    }
}

// Dodajemy importy typów z NearbyUser
public typealias UserCategory = NearbyUser.UserCategory
public typealias UserStatus = NearbyUser.UserStatus
public typealias LocationShareLevel = NearbyUser.LocationShareLevel
