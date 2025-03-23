import SwiftUI
import CoreLocation
//import FirebaseFirestore
//import FirebaseFirestoreSwift

// Przykładowy model profilu użytkownika – dostosuj wg potrzeb
struct UserProfile: Identifiable, Codable {
    var id: String
    var name: String
    var avatarUrl: String?
    var description: String?
    var lastActiveTime: Date
    var helpProvidedCount: Int
    var activeDaysCount: Int
    var thanksReceivedCount: Int
    var helpOffered: [HelpType]
    var status: UserStatus
    var category: UserCategory
    var distance: Double
    var shareLevel: ShareLevel
}

// Przykładowe typy – dostosuj lub rozszerz wg wymagań
enum HelpType: String, Codable, Hashable {
    case technical, tools
    var icon: String {
        switch self {
        case .technical: return "wrench.fill"
        case .tools: return "hammer.fill"
        }
    }
    var localizedName: String {
        switch self {
        case .technical: return "Wsparcie techniczne"
        case .tools: return "Narzędzia"
        }
    }
}

enum UserStatus: String, Codable {
    case available, busy, needsHelp, offering, temporary
    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .busy: return "xmark.octagon.fill"
        case .needsHelp: return "exclamationmark.circle.fill"
        case .offering: return "hand.thumbsup.fill"
        case .temporary: return "clock.fill"
        }
    }
    var localizedName: String {
        switch self {
        case .available: return "Dostępny"
        case .busy: return "Zajęty"
        case .needsHelp: return "Potrzebuje pomocy"
        case .offering: return "Oferuje pomoc"
        case .temporary: return "Tymczasowy"
        }
    }
}

enum UserCategory: String, Codable {
    case help, info, social  // Dodany przypadek "social"
    var icon: String {
        switch self {
        case .help: return "person.2.fill"
        case .info: return "info.circle.fill"
        case .social: return "person.crop.circle"
        }
    }
    var localizedName: String {
        switch self {
        case .help: return "Pomoc"
        case .info: return "Informacje"
        case .social: return "Społeczność"
        }
    }
}

enum ShareLevel: String, Codable {
    case exact, approximate
}

struct UserProfileView: View {
    var profile: UserProfile? = nil
    // Zmieniamy domyślną wartość na true, aby widoczny był przycisk "Edytuj"
    var isOwnProfile: Bool = true
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var peopleService = PeopleLocationService.shared
    @State private var showingReportSheet = false
    @State private var showEditProfile = false
    
    // W trybie edycji będziemy korzystać z kopii profilu, którą można modyfikować
    @State private var editableProfile: UserProfile = UserProfile(
        id: "",
        name: "",
        avatarUrl: nil,
        description: nil,
        lastActiveTime: Date(),
        helpProvidedCount: 0,
        activeDaysCount: 0,
        thanksReceivedCount: 0,
        helpOffered: [],
        status: .available,
        category: .social,
        distance: 0,
        shareLevel: .approximate
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Debugowy tekst, by sprawdzić wartość isOwnProfile
                    Text("isOwnProfile = \(isOwnProfile.description)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    profileHeader
                    statsSection
                    statusSection
                    
                    if !isOwnProfile {
                        locationSection
                    }
                    
                    if let profile = profile, !profile.helpOffered.isEmpty {
                        helpOfferedSection
                    }
                    
                    availabilitySection
                    achievementsSection
                    
                    if !isOwnProfile {
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle(isOwnProfile ? "Mój Profil" : "Profil użytkownika")
            .navigationBarItems(trailing: navBarButtons)
            .actionSheet(isPresented: $showingReportSheet) {
                ActionSheet(
                    title: Text("Zgłoś użytkownika"),
                    message: Text("Wybierz powód zgłoszenia"),
                    buttons: [
                        .default(Text("Niewłaściwe zachowanie")) {
                            reportUser("Niewłaściwe zachowanie")
                        },
                        .default(Text("Spam")) {
                            reportUser("Spam")
                        },
                        .default(Text("Fałszywe informacje")) {
                            reportUser("Fałszywe informacje")
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile = profile {
                    EditProfileView(profile: $editableProfile)
                        .onAppear {
                            editableProfile = profile
                        }
                }
            }
        }
    }
    
    // MARK: - Navigation Bar Buttons
    private var navBarButtons: some View {
        HStack {
            if isOwnProfile {
                Button("Edytuj") {
                    showEditProfile = true
                }
            }
            Button("Zamknij") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeader: some View {
        VStack(spacing: 12) {
            if let avatarUrlString = profile?.avatarUrl, let url = URL(string: avatarUrlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
            }
            
            Text(profile?.name ?? "Użytkownik")
                .font(.title2)
                .bold()
            
            if let description = profile?.description {
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Aktywny: \(timeAgoString(from: profile?.lastActiveTime ?? Date()))",
                      systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Statystyki")
            
            HStack(spacing: 20) {
                statItem(
                    count: "\(profile?.helpProvidedCount ?? 0)",
                    title: "Udzielona pomoc",
                    icon: "heart.fill",
                    color: .red
                )
                statItem(
                    count: "\(profile?.activeDaysCount ?? 0)",
                    title: "Dni aktywności",
                    icon: "calendar",
                    color: .blue
                )
                statItem(
                    count: "\(profile?.thanksReceivedCount ?? 0)",
                    title: "Podziękowania",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Availability Section
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Dostępność")
            
            VStack(alignment: .leading, spacing: 8) {
                availabilityRow(day: "Poniedziałek - Piątek", hours: "9:00 - 17:00")
                availabilityRow(day: "Weekendy", hours: "10:00 - 14:00")
            }
        }
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Osiągnięcia")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    achievementBadge(
                        icon: "star.fill",
                        title: "Pomocny",
                        description: "Pomógł 10 osobom",
                        color: .yellow
                    )
                    achievementBadge(
                        icon: "clock.fill",
                        title: "Aktywny",
                        description: "30 dni w aplikacji",
                        color: .blue
                    )
                    achievementBadge(
                        icon: "hand.thumbsup.fill",
                        title: "Zaufany",
                        description: "5 pozytywnych ocen",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Views for Stats and Achievements
    private func statItem(count: String, title: String, icon: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text(count)
                .font(.headline)
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func achievementBadge(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .bold()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Status")
            
            HStack(spacing: 16) {
                if let profile = profile {
                    statusBadge(
                        icon: profile.status.icon,
                        text: profile.status.localizedName,
                        color: statusColor
                    )
                    
                    statusBadge(
                        icon: profile.category.icon,
                        text: profile.category.localizedName,
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Location Section (tylko dla cudzych profili)
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Lokalizacja")
            
            if let profile = profile {
                HStack {
                    Image(systemName: "location.circle.fill")
                    Text(String(format: "%.1f km od Ciebie", profile.distance))
                }
                
                if profile.shareLevel != .exact {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                        Text("Lokalizacja przybliżona")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    if let userId = UUID(uuidString: profile.id) {
                        peopleService.requestLocationSharing(with: userId)
                    }
                }) {
                    Label("Poproś o dokładną lokalizację", systemImage: "location.fill")
                }
                .disabled(profile.shareLevel == .exact)
            }
        }
    }
    
    // MARK: - Help Offered Section
    private var helpOfferedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Oferowana pomoc")
            
            if let profile = profile {
                FlowLayout(spacing: 8) {
                    ForEach(profile.helpOffered, id: \.self) { helpType in
                        HStack {
                            Image(systemName: helpType.icon)
                            Text(helpType.localizedName)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons (dla cudzych profili)
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Logika rozpoczęcia czatu
            }) {
                Label("Wyślij wiadomość", systemImage: "message.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            HStack {
                if let profile = profile {
                    Button(action: {
                        if let userId = UUID(uuidString: profile.id) {
                            peopleService.blockUser(userId)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Zablokuj", systemImage: "hand.raised.fill")
                            .padding()
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        showingReportSheet = true
                    }) {
                        Label("Zgłoś", systemImage: "exclamationmark.triangle.fill")
                            .padding()
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Pomocnicze funkcje i widoki
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.secondary)
    }
    
    private func availabilityRow(day: String, hours: String) -> some View {
        HStack {
            Text(day)
                .foregroundColor(.secondary)
            Spacer()
            Text(hours)
                .bold()
        }
    }
    
    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(20)
    }
    
    private var statusColor: Color {
        guard let profile = profile else { return .gray }
        switch profile.status {
        case .available: return .blue
        case .busy: return .gray
        case .needsHelp: return .red
        case .offering: return .green
        case .temporary: return .orange
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func reportUser(_ reason: String) {
        if let profile = profile, let userId = UUID(uuidString: profile.id) {
            peopleService.reportUser(userId, reason: reason)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Widok Edycji Profilu

struct EditProfileView: View {
    @Binding var profile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var peopleService = PeopleLocationService.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dane osobowe")) {
                    TextField("Nazwa", text: $profile.name)
                    TextField("Avatar URL", text: Binding(
                        get: { profile.avatarUrl ?? "" },
                        set: { profile.avatarUrl = $0 }
                    ))
                }
                Section(header: Text("Opis")) {
                    TextEditor(text: Binding(
                        get: { profile.description ?? "" },
                        set: { profile.description = $0 }
                    ))
                    .frame(height: 150)
                }
            }
            .navigationTitle("Edytuj profil")
            .navigationBarItems(
                leading: Button("Anuluj") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Zapisz") {
                    peopleService.updateProfile(profile)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Przykładowy FlowLayout

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            content
                .fixedSize()
                .alignmentGuide(.leading, computeValue: { d in
                    if abs(width - d.width) > geometry.size.width {
                        width = 0
                        height -= d.height
                    }
                    let result = width
                    if d.width != geometry.size.width {
                        width -= d.width
                    }
                    return result
                })
                .alignmentGuide(.top, computeValue: { d in
                    let result = height
                    if d.width != geometry.size.width {
                        height = 0
                    }
                    return result
                })
        }
    }
}
