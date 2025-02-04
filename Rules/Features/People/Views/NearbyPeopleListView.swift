//NearbyPeopleListView.swift
import SwiftUI

struct NearbyPeopleListView: View {
    @ObservedObject private var peopleService = PeopleLocationService.shared
    @State private var searchText = ""
    @State private var selectedCategory: NearbyUser.UserCategory?
    @State private var showOnlyAvailable = false
    @State private var selectedRadius: Double = 5.0
    @State private var showingFilters = false
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
            case list
            case map
        }
    
    var filteredUsers: [NearbyUser] {
        var users = peopleService.nearbyUsers
        
        if !searchText.isEmpty {
            users = users.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if showOnlyAvailable {
            users = users.filter { $0.status == .available }
        }
        
        return users
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // Przełącznik widoku
                Picker("Widok", selection: $viewMode) {
                    Image(systemName: "list.bullet")
                        .tag(ViewMode.list)
                    Image(systemName: "map")
                        .tag(ViewMode.map)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Zawartość
                if viewMode == .list {
                    if filteredUsers.isEmpty {
                        EmptyStateView()
                    } else {
                        List(filteredUsers) { user in
                            UserListRow(user: user)
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                } else {
                    PeopleMapView()
                }
            }
            .navigationTitle("Osoby w pobliżu")
            .searchable(text: $searchText, prompt: Text("Szukaj"))
            .refreshable {
                peopleService.refreshData()
            }
            .navigationBarItems(trailing: Button(action: {
                showingFilters = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
            })
            .sheet(isPresented: $showingFilters) {
                FilterView(showOnlyAvailable: $showOnlyAvailable)
            }
        }
    }

struct UserStatusView: View {
    let status: NearbyUser.UserStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status == .available ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(status.localizedName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct UserListRow: View {
    let user: NearbyUser
    @State private var showingProfile = false
    
    var body: some View {
        Button(action: { showingProfile.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: user.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.name)
                            .font(.headline)
                        UserStatusView(status: user.status)
                    }
                    if let description = user.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f km", user.distance))
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    if user.shareLevel == .exact {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileView(user: user)
        }
    }
}

struct NearbyPeopleListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NearbyPeopleListView()
                .preferredColorScheme(.light)
            NearbyPeopleListView()
                .preferredColorScheme(.dark)
        }
    }
}
