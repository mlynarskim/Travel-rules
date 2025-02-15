//TravelListView.swift
import SwiftUI
import Combine

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

struct CustomSegmentedControl: UIViewRepresentable {
    @Binding var selectedTab: Int
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: ["my_checklist".appLocalized, "packing_list".appLocalized])
        control.selectedSegmentIndex = 0
        control.backgroundColor = UIColor(themeColors.primary).withAlphaComponent(0.7)
        control.selectedSegmentTintColor = UIColor(themeColors.primary)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        uiView.selectedSegmentIndex = selectedTab
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomSegmentedControl
        
        init(_ parent: CustomSegmentedControl) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UISegmentedControl) {
            withAnimation(.easeInOut(duration: 0.3)) {
                parent.selectedTab = sender.selectedSegmentIndex
            }
            HapticManager.shared.impact(style: .light)
        }
    }
}

struct TravelListView: View {
    @State private var travelItems: [TravelItem] = []
    @State private var newItemName: String = ""
    @State private var selectedTab: Int = 0
    @State private var showExportSheet = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isDarkMode") private var isDarkMode = false
    @ObservedObject private var keyboard = KeyboardResponder()
    @StateObject private var languageManager = LanguageManager.shared
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var isSmallDevice: Bool {
        screenHeight <= 667 // iPhone SE, 7, 8
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationView {
                    ZStack {
                        // Tło: obrazek dopasowany do ekranu
                        let imageName = "\(selectedTheme)-bg\(isDarkMode ? "-dark" : "")"
                        
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        
                        // Główny kontent
                        VStack(spacing: isSmallDevice ? 8 : 16) {
                            // Górny pasek z przyciskiem export
                            HStack {
                                Spacer()
                                Button(action: {
                                    HapticManager.shared.impact(style: .medium)
                                    showExportSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: isSmallDevice ? 18 : 20))
                                        .foregroundColor(.white)
                                        .padding(isSmallDevice ? 8 : 10)
                                        .background(themeColors.primary)
                                        .cornerRadius(10)
                                }
                                .padding(.trailing)
                            }
                            .padding(.top, isSmallDevice ? 8 : 16)
                            
                            // Segmented Control
                            CustomSegmentedControl(selectedTab: $selectedTab)
                                .frame(height: 40)
                                .padding(.horizontal)
                                .padding(.top, isSmallDevice ? 12 : 20)
                            
                            // Treść w zależności od zakładki
                            if selectedTab == 0 {
                                MyListContent(
                                    travelItems: $travelItems,
                                    newItemName: $newItemName,
                                    geometry: geometry,
                                    themeColors: themeColors
                                )
                            } else {
                                TravelChecklist()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.clear)
                            }
                        }
                    }
                    .navigationBarHidden(false)
                }
                .ignoresSafeArea() // ← Kluczowe, by NavigationView nie dokładało białych obszarów
            }
            // Arkusz exportu
            .sheet(isPresented: $showExportSheet) {
                ExportView(items: travelItems.map { $0.name }, themeColors: themeColors)
            }
            .onAppear {
                loadItems()
            }
            .onDisappear {
                saveItems()
            }
        }
    }
    
    // Funkcje pomocnicze w TravelListView
    private func addItem() {
        guard !newItemName.isEmpty else { return }
        let newItem = TravelItem(name: newItemName)
        withAnimation(.spring()) {
            travelItems.append(newItem)
        }
        newItemName = ""
    }
    
    private func toggleCompletion(for item: TravelItem) {
        if let index = travelItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.easeInOut) {
                travelItems[index].isCompleted.toggle()
            }
        }
    }
    
    private func deleteItem(_ item: TravelItem) {
        if let index = travelItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.easeOut) {
                travelItems.remove(at: index)
            }
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(travelItems) {
            UserDefaults.standard.set(encoded, forKey: "travelItems")
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "travelItems") {
            if let decoded = try? JSONDecoder().decode([TravelItem].self, from: data) {
                travelItems = decoded
            }
        }
    }
}

// MARK: - MyListContent
struct MyListContent: View {
    @Binding var travelItems: [TravelItem]
    @Binding var newItemName: String
    let geometry: GeometryProxy
    let themeColors: ThemeColors
    
    private var isSmallDevice: Bool {
        geometry.size.height <= 667
    }
    
    var body: some View {
        VStack(spacing: isSmallDevice ? 8 : 12) {
            // Dodajemy pole tekstowe + przycisk "Add"
            HStack {
                TextField("enter_new_item".appLocalized, text: $newItemName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: isSmallDevice ? 14 : 16))
                    .padding(.leading, isSmallDevice ? 16 : 20)
                
                Button(action: addItem) {
                    Text("add".appLocalized)
                        .font(.system(size: isSmallDevice ? 14 : 16, weight: .semibold))
                        .frame(width: isSmallDevice ? 70 : 80, height: isSmallDevice ? 32 : 35)
                        .background(themeColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
                }
                .padding(.trailing, isSmallDevice ? 16 : 20)
            }
            .padding(.vertical, isSmallDevice ? 8 : 10)
            
            // Lista z zadaniami
            List {
                ForEach(travelItems) { item in
                    ItemRow(
                        item: item,
                        isSmallDevice: isSmallDevice,
                        themeColors: themeColors,
                        toggleCompletion: { toggleItemCompletion(item) },
                        deleteItem: { deleteItem(item) }
                    )
                    .listRowBackground(Color.clear) // tło wiersza puste
                }
            }
            .listStyle(PlainListStyle())
            // iOS 16+ - usuwa domyślne tło listy, żeby nie pojawiał się biały obszar
            .background(Color.clear)
            .onAppear {
                if #available(iOS 16.0, *) {
                    UITableView.appearance().backgroundColor = .clear
                    // lub: .scrollContentBackground(.hidden) na samej Liście,
                    // ale tak jest bardziej uniwersalnie (i do iOS 15)
                } else {
                    UITableView.appearance().backgroundColor = .clear
                }
            }
        }
    }
    
    private func addItem() {
        guard !newItemName.isEmpty else { return }
        let newItem = TravelItem(name: newItemName)
        withAnimation(.spring()) {
            travelItems.append(newItem)
        }
        newItemName = ""
        HapticManager.shared.impact(style: .medium)
    }
    
    private func toggleItemCompletion(_ item: TravelItem) {
        if let index = travelItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.easeInOut) {
                travelItems[index].isCompleted.toggle()
            }
            HapticManager.shared.impact(style: .light)
        }
    }
    
    private func deleteItem(_ item: TravelItem) {
        withAnimation(.easeOut) {
            travelItems.removeAll(where: { $0.id == item.id })
        }
        HapticManager.shared.notification(type: .success)
    }
}

// MARK: - ItemRow
struct ItemRow: View {
    let item: TravelItem
    let isSmallDevice: Bool
    let themeColors: ThemeColors
    let toggleCompletion: () -> Void
    let deleteItem: () -> Void
    
    var body: some View {
        HStack {
            // Checkmark
            Button(action: toggleCompletion) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? themeColors.success : .white)
                    .font(.system(size: isSmallDevice ? 16 : 18))
                    .padding(.horizontal, isSmallDevice ? 8 : 10)
            }
            // Nazwa zadania
            Text(item.name)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? themeColors.secondaryText : .white)
                .font(.system(size: isSmallDevice ? 16 : 18, weight: .semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Ikona kosza
            Button(action: deleteItem) {
                Image(systemName: "trash")
                    .foregroundColor(themeColors.error)
                    .font(.system(size: isSmallDevice ? 14 : 16))
            }
            .padding(.horizontal, isSmallDevice ? 8 : 10)
        }
        .frame(height: isSmallDevice ? 36 : 40)
        .background(themeColors.primary)
        .cornerRadius(15)
        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - ExportView
struct ExportView: View {
    let items: [String]
    let themeColors: ThemeColors
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("exportOptions".appLocalized)
                    .font(.title)
                    .foregroundColor(themeColors.primaryText)
                    .padding()
                
                ExportButtonView(
                    items: items,
                    title: "myTravelList".appLocalized,
                    category: "travelChecklist".appLocalized
                )
                .padding()
                
                Spacer()
            }
            .background(themeColors.cardBackground)
            .navigationBarItems(trailing: Button("done".appLocalized) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview
struct TravelListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TravelListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE")
                .environment(\.colorScheme, .light)
            
            TravelListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
                .previewDisplayName("iPhone 8")
                .environment(\.colorScheme, .light)
            
            TravelListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
                .previewDisplayName("iPhone 14")
                .environment(\.colorScheme, .light)
            
            TravelListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
                .previewDisplayName("iPhone 14 Pro Max")
                .environment(\.colorScheme, .light)
            
            TravelListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
                .previewDisplayName("iPhone 14 (Dark Mode)")
                .environment(\.colorScheme, .dark)
        }
    }
}

