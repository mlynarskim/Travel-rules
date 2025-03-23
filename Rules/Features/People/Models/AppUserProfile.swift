import Foundation
//import FirebaseFirestore
//import FirebaseFirestoreSwift

public struct AppUserProfile: Codable {
    public let id: String            // UID z Firebase
    public var email: String         // Email użytkownika (wymagany)
    public var name: String          // Nazwa użytkownika (wymagana)
    public var lastActiveTime: Date
    public var helpProvidedCount: Int
    public var activeDaysCount: Int
    public var thanksReceivedCount: Int
    public var distance: Double
    
    public var category: UserCategory
    public var status: UserStatus
    public var shareLevel: LocationShareLevel
    
    public var helpOffered: [HelpType]
    
    public var preferences: UserPreferences
    
    // Konstruktor z wartościami domyślnymi
    public init(
        id: String,
        email: String,
        name: String,
        lastActiveTime: Date = Date(),
        helpProvidedCount: Int = 0,
        activeDaysCount: Int = 0,
        thanksReceivedCount: Int = 0,
        distance: Double = 0.0,
        category: UserCategory = .social,
        status: UserStatus = .available,
        shareLevel: LocationShareLevel = .approximate,
        helpOffered: [HelpType] = [],
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.lastActiveTime = lastActiveTime
        self.helpProvidedCount = helpProvidedCount
        self.activeDaysCount = activeDaysCount
        self.thanksReceivedCount = thanksReceivedCount
        self.distance = distance
        self.category = category
        self.status = status
        self.shareLevel = shareLevel
        self.helpOffered = helpOffered
        self.preferences = preferences
    }
    
    // MARK: - Typy pomocnicze
    public enum HelpType: String, Codable {
        case technical, tools, transport, social, resources, childcare
    }
    
    public struct UserPreferences: Codable {
        public init() { }
        // Dodaj pola i inicjalizatory według potrzeb
    }
    
    public enum UserCategory: String, Codable {
        case social, help, info
    }
    
    public enum UserStatus: String, Codable {
        case available, busy, needsHelp
    }
    
    public enum LocationShareLevel: String, Codable {
        case approximate, exact
    }
}
