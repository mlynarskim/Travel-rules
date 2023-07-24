import Foundation
import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
    var _center: NotificationCenter
    var _keyboardShow: AnyCancellable?
    var _keyboardHide: AnyCancellable?
    
    init(center: NotificationCenter = .default) {
        _center = center
        _keyboardShow = _center.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .subscribe(on: DispatchQueue.main)
            .assign(to: \.currentHeight, on: self)
        
        _keyboardHide = _center.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat.zero }
            .subscribe(on: DispatchQueue.main)
            .assign(to: \.currentHeight, on: self)
    }
}

struct TravelItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var isCompleted: Bool = false
    var isDeleted: Bool = false
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

struct TravelListView: View {
    @State private var travelItems: [TravelItem] = []
    @State private var newItemName: String = ""
    @State private var selectedTab: Int = 0
    @State private var showBathroomItems = false
    @State private var showKitchenItems = false
    @State private var showClothesItems = false
    @State private var showUsefulItems = false
    @State private var showElectronicsItems = false
    @State private var showCampingItems = false
    @State private var showToolsItems = false
    @State private var showOtherItems = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @ObservedObject private var keyboard = KeyboardResponder()

    
    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            selectedTab = 0
                        }) {
                            Text("My Checklist")
                                .font(.headline)
                                .foregroundColor(selectedTab == 0 ? .white : .black)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(selectedTab == 0 ? Color(hex: "#29606D") : Color.clear)
                        .cornerRadius(15)
                        Button(action: {
                            selectedTab = 1
                        }) {
                            Text("Packing List")
                                .font(.headline)
                                .foregroundColor(selectedTab == 1 ? .white : .black)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(selectedTab == 1 ? Color(hex: "#29606D") : Color.clear)
                        .cornerRadius(15)
                        
                    }
                    .padding(.top, 20)
                    if selectedTab == 0 {
                        VStack {
                            HStack {
                                TextField("Enter new item", text: $newItemName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.leading, 20.0)
                                
                                Button(action: {
                                    addItem()
                                }) {
                                    Text("Add")
                                        .frame(width: 80, height: 35.0)
                                        .background(Color(hex: "#29606D"))
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        .padding(.trailing, 20.0)
                                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            
                            List(travelItems) { item in
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        toggleCompletion(for: item)
                                    }) {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isCompleted ? .green : .white)
                                            .padding(.horizontal, 10)
                                    }
                                    Text(item.name)
                                        .strikethrough(item.isCompleted)
                                        .foregroundColor(item.isCompleted ? .gray : .white)
                                        .font(.custom("Lato Bold", size: 20))
                                        .lineLimit(1)
                                    
                                        .frame(maxWidth: .infinity)
                                    Button(action: {
                                        deleteItem(item)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .padding(.horizontal, 10)
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                }
                                .frame(height: 40)
                                .background(Color(hex: "#29606D"))
                                .cornerRadius(15)
                                .listRowBackground(Color.clear)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .listStyle(PlainListStyle())
                        }
                    } else if selectedTab == 1 {
                        TravelChecklist()
                    }
                }
            }
            .onAppear {
                loadItems()
            }
            .onDisappear {
                saveItems()
            }
            .padding(.top, keyboard.currentHeight) // Dodajemy padding na dole w zależności od wysokości klawiatury
            .animation(.easeInOut(duration: 0.1))
        }
        .navigationTitle("Travel Checklist")
    }
        func addItem() {
            guard !newItemName.isEmpty else { return }
            let newItem = TravelItem(name: newItemName)
            travelItems.append(newItem)
            newItemName = ""
        }
        
        func toggleCompletion(for item: TravelItem) {
            if let index = travelItems.firstIndex(where: { $0.id == item.id }) {
                travelItems[index].isCompleted.toggle()
            }
        }
        
        func deleteItem(_ item: TravelItem) {
            if let index = travelItems.firstIndex(where: { $0.id == item.id }) {
                travelItems.remove(at: index)
            }
        }
        
        func saveItems() {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(travelItems) {
                UserDefaults.standard.set(encoded, forKey: "travelItems")
            }
        }
        
        func loadItems() {
            if let data = UserDefaults.standard.data(forKey: "travelItems") {
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode([TravelItem].self, from: data) {
                    travelItems = decoded
                }
            }
        }
    }


struct TravelListView_Previews: PreviewProvider {
    static var previews: some View {
        TravelListView()
    }
}
