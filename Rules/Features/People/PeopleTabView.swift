//PeopleTabView.swift
import SwiftUI
import CoreLocation

struct PeopleTabView: View {
   @Environment(\.colorScheme) var colorScheme
   @ObservedObject private var peopleService = PeopleLocationService.shared
   @ObservedObject private var authService = AuthenticationService.shared
   @State private var selectedTab = 0
   let user: NearbyUser

   init(user: NearbyUser? = nil) {
       self.user = user ?? NearbyUser(
           id: UUID(),
           name: "Użytkownik",
           status: .available,
           category: .social,
           location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
           distance: 0,
           shareLevel: .approximate,
           description: nil
       )
   }

   var body: some View {
       Group {
           TabView(selection: $selectedTab) {
               PeopleMapView()
                   .tabItem {
                       Label("Mapa", systemImage: "map.fill")
                   }
                   .tag(0)
               
               NearbyPeopleListView()
                   .tabItem {
                       Label("Lista", systemImage: "list.bullet")
                   }
                   .tag(1)
               
               ChatListView()
                   .tabItem {
                       Label("Czat", systemImage: "message.fill")
                   }
                   .tag(2)
               
               Group {
                   if authService.isAuthenticated {
                       UserProfileView()
                   } else {
                       LoginView()
                   }
               }
               .tabItem {
                   Label("Profil", systemImage: "person.fill")
               }
               .tag(3)
           }
           .accentColor(colorScheme == .dark ? .white : .blue)
       }
   }
}
