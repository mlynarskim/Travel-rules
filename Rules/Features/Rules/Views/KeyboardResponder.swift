import Foundation
import SwiftUI
import Combine

// MARK: - Models and Helpers
class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
    private var center: NotificationCenter
    private var keyboardShow: AnyCancellable?
    private var keyboardHide: AnyCancellable?
    
    init(center: NotificationCenter = .default) {
        self.center = center
        setupPublishers()
    }
    
    private func setupPublishers() {
        keyboardShow = center.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentHeight, on: self)
        
        keyboardHide = center.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat.zero }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentHeight, on: self)
    }
}

struct TravelItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var isDeleted: Bool
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isCompleted = false
        self.isDeleted = false
    }
}

// MARK: - Main View
struct TravelListView: View {
    // MARK: - Properties
    @StateObject private var keyboard = KeyboardResponder()
    @StateObject private var languageManager = LanguageManager.shared
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    @State private var travelItems: [TravelItem] = []
    @State private var newItemName = ""
    @State private var selectedTab = 0
    @State private var showExportSheet = false
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return .classicTheme
        case .mountain: return .mountainTheme
        case .beach: return .beachTheme
        case .desert: return .desertTheme
        case .forest: return .forestTheme
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Image(isDarkMode ? themeColors.darkBackground : themeColors.background)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Export Button
                    exportButton
                    
                    Spacer()
                    
                    // Tab Selection
                    tabSelectionView
                    
                    // Content
                    if selectedTab == 0 {
                        myChecklistView
                    } else {
                        TravelChecklist()
                    }
                }
                .padding(.top, keyboard.currentHeight)
                .animation(.easeInOut(duration: 0.16))
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(items: travelItems.map(\.name))
        }
        .navigationTitle("travel_checklist".appLocalized)
        .onAppear(perform: loadItems)
        .onDisappear(perform: saveItems)
    }
    
    // MARK: - Subviews
    private var exportButton: some View {
        HStack {
            Spacer()
            Button(action: { showExportSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(themeColors.lightText)
                    .padding(10)
                    .background(themeColors.primary)
                    .cornerRadius(10)
                    .shadow(color: themeColors.cardShadow, radius: 5)
            }
            .padding(.trailing)
        }
        .padding(.top)
    }
    
    private var tabSelectionView: some View {
        HStack {
            TabButton(
                title: "my_checklist".appLocalized,
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                title: "packing_list".appLocalized,
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
        }
        .padding(.top, 20)
    }
    
    private var myChecklistView: some View {
        VStack {
            // Input Field
            HStack {
                TextField("enter_new_item".appLocalized, text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: addItem) {
                    Text("add".appLocalized)
                        .frame(width: 80, height: 35)
                        .background(themeColors.primary)
                        .foregroundColor(themeColors.lightText)
                        .cornerRadius(15)
                        .shadow(color: themeColors.cardShadow, radius: 5)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 10)
            
            // Items List
            itemsList
        }
    }
    
    private var itemsList: some View {
        List(travelItems) { item in
            ItemRow(
                item: item,
                themeColors: themeColors,
                onToggle: { toggleCompletion(for: item) },
                onDelete: { deleteItem(item) }
            )
            .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Methods
    private func addItem() {
        guard !newItemName.isEmpty else { return }
        let newItem = TravelItem(name: newItemName)
        travelItems.append(newItem)
        newItemName = ""
        HapticFeedback.success()
    }
    
    private func toggleCompletion(for item: TravelItem) {
        withAnimation {
            if let index = travelItems.firstIndex(where: { $0.id == item.id }) {
                travelItems[index].isCompleted.toggle()
                HapticFeedback.light()
            }
        }
    }
    
    private func deleteItem(_ item: TravelItem) {
        withAnimation {
            travelItems.removeAll(where: { $0.id == item.id })
            HapticFeedback.error()
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(travelItems) {
            UserDefaults.standard.set(encoded, forKey: "travelItems")
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "travelItems"),
           let decoded = try? JSONDecoder().decode([TravelItem].self, from: data) {
            travelItems = decoded
        }
    }
}

// MARK: - Supporting Views
struct ItemRow: View {
    let item: TravelItem
    let themeColors: ThemeColors
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: onToggle) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? themeColors.success : themeColors.lightText)
                    .padding(.horizontal, 10)
            }
            
            Text(item.name)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? themeColors.secondaryText : themeColors.lightText)
                .font(.custom("Lato Bold", size: 20))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(themeColors.error)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.horizontal, 10)
        }
        .frame(height: 40)
        .background(themeColors.primary)
        .cornerRadius(15)
        .shadow(color: themeColors.cardShadow, radius: 5)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .black)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(isSelected ? Color(hex: "#29606D") : Color.clear)
                .cornerRadius(15)
        }
    }
}

// Kontynuacja w następnej odpowiedzi...