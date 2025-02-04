//UserProfileView.swift
import SwiftUI
import CoreLocation

struct UserProfileView: View {
    var user: NearbyUser? = nil
    var isOwnProfile: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var peopleService = PeopleLocationService.shared
    @State private var showingReportSheet = false
    @State private var reportReason = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsSection
                    statusSection
                    
                    if !isOwnProfile {
                        locationSection
                    }
                    
                    if let user = user, !user.helpOffered.isEmpty {
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
            .navigationBarItems(trailing: Button("Zamknij") {
                presentationMode.wrappedValue.dismiss()
            })
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
        }
    }
    
    // Profile Header Section
    private var profileHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text(user?.name ?? "Użytkownik")
                .font(.title2)
                .bold()
            
            if let description = user?.description {
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Aktywny: \(timeAgoString(from: user?.lastActiveTime ?? Date()))",
                      systemImage: "clock.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    // Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Statystyki")
            
            HStack(spacing: 20) {
                statItem(
                    count: "\(user?.helpProvidedCount ?? 0)",
                    title: "Udzielona pomoc",
                    icon: "heart.fill",
                    color: .red
                )
                statItem(
                    count: "\(user?.activeDaysCount ?? 0)",
                    title: "Dni aktywności",
                    icon: "calendar",
                    color: .blue
                )
                statItem(
                    count: "\(user?.thanksReceivedCount ?? 0)",
                    title: "Podziękowania",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // Availability Section
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Dostępność")
            
            VStack(alignment: .leading, spacing: 8) {
                availabilityRow(day: "Poniedziałek - Piątek", hours: "9:00 - 17:00")
                availabilityRow(day: "Weekendy", hours: "10:00 - 14:00")
            }
        }
    }
    
    // Achievements Section
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
    
    // Helper Views for Stats and Achievements
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
    // Status Section
        private var statusSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Status")
                
                HStack(spacing: 16) {
                    if let user = user {
                        statusBadge(
                            icon: user.status.icon,
                            text: user.status.localizedName,
                            color: statusColor
                        )
                        
                        statusBadge(
                            icon: user.category.icon,
                            text: user.category.localizedName,
                            color: .blue
                        )
                    }
                }
            }
        }
        
        // Location Section
        private var locationSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Lokalizacja")
                
                if let user = user {
                    HStack {
                        Image(systemName: "location.circle.fill")
                        Text(String(format: "%.1f km od Ciebie", user.distance))
                    }
                    
                    if user.shareLevel != .exact {
                        HStack {
                            Image(systemName: "eye.slash.fill")
                            Text("Lokalizacja przybliżona")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        peopleService.requestLocationSharing(with: user.id)
                    }) {
                        Label("Poproś o dokładną lokalizację", systemImage: "location.fill")
                    }
                    .disabled(user.shareLevel == .exact)
                }
            }
        }
        
        // Help Offered Section
        private var helpOfferedSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Oferowana pomoc")
                
                if let user = user {
                    FlowLayout(spacing: 8) {
                        ForEach(user.helpOffered, id: \.self) { helpType in
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
        
        // Action Buttons
        private var actionButtons: some View {
            VStack(spacing: 12) {
                Button(action: {
                    // Tu dodaj logikę czatu
                }) {
                    Label("Wyślij wiadomość", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                HStack {
                    if let user = user {
                        Button(action: {
                            peopleService.blockUser(user.id)
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
        
        // Helper Functions and Views
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
            guard let user = user else { return .gray }
            switch user.status {
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
            if let user = user {
                peopleService.reportUser(user.id, reason: reason)
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
struct FlowLayout: View {
    let spacing: CGFloat
    let content: [AnyView]
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> some View) {
        self.spacing = spacing
        self.content = [AnyView(content())]
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
            ForEach(self.content.indices, id: \.self) { index in
                self.content[index]
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { dimensions in
                        if abs(width - dimensions.width) > geometry.size.width {
                            width = 0
                            height -= dimensions.height
                        }
                        let result = width
                        if index == self.content.count - 1 {
                            width = 0
                        } else {
                            width -= dimensions.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == self.content.count - 1 {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}
    // Preview
    struct UserProfileView_Previews: PreviewProvider {
        static var previews: some View {
            UserProfileView(user: NearbyUser(
                id: UUID(),
                name: "Jan Kowalski",
                status: .offering,
                category: .help,
                location: CLLocationCoordinate2D(latitude: 52.237049, longitude: 21.017532),
                distance: 3.5,
                shareLevel: .approximate,
                description: "Chętnie pomogę z naprawą samochodu",
                helpOffered: [.technical, .tools],
                lastActiveTime: Date(),
                automaticCheckIn: true,
                helpProvidedCount: 15,
                activeDaysCount: 30,
                thanksReceivedCount: 8
            ))
        }
    }
