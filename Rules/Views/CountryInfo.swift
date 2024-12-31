struct EmergencyNumbers: Codable {
    let police: String
    let ambulance: String
    let fire: String
    let general: String
}

struct UsefulLink: Codable {
    let title: String
    let url: String
}

struct CountryInfo: Codable {
    let countryCode: String
    let emergencyNumbers: EmergencyNumbers
    let usefulLinks: [UsefulLink]
    let embassyInfo: String?
}
