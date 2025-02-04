import SwiftUI

struct FilterView: View {
   @Environment(\.presentationMode) var presentationMode
   @ObservedObject private var peopleService = PeopleLocationService.shared
   @Binding var showOnlyAvailable: Bool
   
   private let categories: [NearbyUser.UserCategory] = [
       .social, .help, .family, .camping, .vanlife, .technical, .childcare
   ]
   
   private let helpTypes: [NearbyUser.HelpType] = [
       .technical, .tools, .transport, .social, .resources, .childcare
   ]
   
   @State private var selectedHelpTypes: Set<NearbyUser.HelpType> = []
   @State private var selectedStatus: NearbyUser.UserStatus?
   @State private var selectedRadius: Double = 5.0
   
   var body: some View {
       NavigationView {
           List {
               // Promień wyszukiwania
               Section(header: Text("Promień wyszukiwania")) {
                   VStack(alignment: .leading) {
                       Text("\(Int(selectedRadius)) km")
                           .font(.subheadline)
                           .foregroundColor(.secondary)
                       Slider(value: $selectedRadius, in: 1...15, step: 1)
                           .onChange(of: selectedRadius) { newValue in
                               peopleService.updateSearchRadius(newValue)
                           }
                   }
                   .padding(.vertical, 4)
               }
               
               // Kategorie
               Section(header: Text("Kategorie")) {
                   categoryButton(nil, "Wszystkie", "line.3.horizontal.decrease.circle")
                   ForEach(categories, id: \.self) { category in
                       categoryButton(category, category.localizedName, category.icon)
                   }
               }
               
               // Status
               Section(header: Text("Status użytkownika")) {
                   statusButton(nil, "Wszyscy", "person.3.fill")
                   statusButton(.available, "Dostępni", "checkmark.circle.fill")
                   statusButton(.offering, "Oferujący pomoc", "hand.raised.fill")
                   statusButton(.needsHelp, "Potrzebujący pomocy", "exclamationmark.circle.fill")
               }
               
               // Typy pomocy (tylko gdy wybrana kategoria pomocy)
               if peopleService.searchCategory == .help {
                   Section(header: Text("Typ pomocy")) {
                       ForEach(helpTypes, id: \.self) { helpType in
                           Toggle(isOn: Binding(
                               get: { selectedHelpTypes.contains(helpType) },
                               set: { isSelected in
                                   if isSelected {
                                       selectedHelpTypes.insert(helpType)
                                   } else {
                                       selectedHelpTypes.remove(helpType)
                                   }
                                   updateFilters()
                               }
                           )) {
                               HStack {
                                   Image(systemName: helpType.icon)
                                   Text(helpType.localizedName)
                               }
                           }
                       }
                   }
               }
               
               // Dodatkowe filtry
               Section(header: Text("Dodatkowe filtry")) {
                   Toggle(isOn: $showOnlyAvailable) {
                       HStack {
                           Image(systemName: "person.fill.checkmark")
                           Text("Tylko aktywni użytkownicy")
                       }
                   }
                   .onChange(of: showOnlyAvailable) { _ in
                       updateFilters()
                   }
               }
           }
           .navigationTitle("Filtry")
           .navigationBarItems(
               leading: Button("Wyczyść") {
                   resetFilters()
               },
               trailing: Button("Gotowe") {
                   presentationMode.wrappedValue.dismiss()
               }
           )
           .onAppear {
               // Załaduj aktualne wartości
               selectedRadius = peopleService.selectedRadius
               selectedStatus = peopleService.selectedStatus
               selectedHelpTypes = peopleService.selectedHelpTypes
               showOnlyAvailable = peopleService.showOnlyAvailable
           }
       }
   }
   
   private func categoryButton(_ category: NearbyUser.UserCategory?, _ title: String, _ icon: String) -> some View {
       Button(action: {
           peopleService.setCategory(category)
           updateFilters()
       }) {
           HStack {
               Image(systemName: icon)
               Text(title)
                   .foregroundColor(.primary)
               Spacer()
               if peopleService.searchCategory == category {
                   Image(systemName: "checkmark")
                       .foregroundColor(.accentColor)
               }
           }
       }
   }
   
   private func statusButton(_ status: NearbyUser.UserStatus?, _ title: String, _ icon: String) -> some View {
       Button(action: {
           peopleService.selectedStatus = status
           updateFilters()
       }) {
           HStack {
               Image(systemName: icon)
               Text(title)
                   .foregroundColor(.primary)
               Spacer()
               if peopleService.selectedStatus == status {
                   Image(systemName: "checkmark")
                       .foregroundColor(.accentColor)
               }
           }
       }
   }
   
   private func updateFilters() {
       peopleService.selectedHelpTypes = selectedHelpTypes
       peopleService.showOnlyAvailable = showOnlyAvailable
       peopleService.refreshData()
   }
   
   private func resetFilters() {
       selectedRadius = 5.0
       peopleService.updateSearchRadius(5.0)
       selectedStatus = nil
       peopleService.selectedStatus = nil
       selectedHelpTypes = []
       peopleService.selectedHelpTypes = []
       showOnlyAvailable = false
       peopleService.showOnlyAvailable = false
       peopleService.setCategory(nil)
       peopleService.refreshData()
   }
}

