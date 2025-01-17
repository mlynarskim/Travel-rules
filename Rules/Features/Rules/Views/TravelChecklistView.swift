//TravelChecklistView.swift
import SwiftUI
import Foundation

struct TravelChecklist: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedTab: ListItem?
    @State private var scrollToTop: Bool = false
    @State private var items: [ListItemView] = []
    @StateObject private var languageManager = LanguageManager.shared
    @State private var completedItems: [ListItem: Set<Int>] = [:]
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("selectedTheme") private var selectedTheme: String = "classic"
    
    init() {
        loadCompletedItems()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: geometry.size.width <= 375 ? 8 : 12) {
                        ForEach(items) { listItem in
                            CategoryButton(
                                listItem: listItem,
                                selectedTab: $selectedTab,
                                geometry: geometry,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        selectedTab = listItem.type
                                        scrollToTop = true
                                    }
                                    HapticManager.shared.impact(style: .light)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, geometry.size.width <= 375 ? 12 : 16)
                    .padding(.top, geometry.size.height <= 667 ? 8 : 16)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, adaptiveDividerPadding(geometry))
                
                
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack(spacing: adaptiveListSpacing(geometry)) {
                            ForEach(items) { listItem in
                                CategorySection(
                                    listItem: listItem,
                                    items: getListItems(for: listItem.type),
                                    completedItems: $completedItems,
                                    geometry: geometry
                                )
                            }
                        }
                        .padding(.vertical, adaptiveVerticalPadding(geometry))
                        
                    }
                    .onChange(of: selectedTab) { newValue in
                        if let type = newValue, scrollToTop {
                            withAnimation {
                                scrollViewProxy.scrollTo(type.rawValue, anchor: .top)
                                
                            }
                            scrollToTop = false
                        }
                    }
                }
            }
        }
        
        .onAppear {
            loadCompletedItems()
            updateLocalizedData()
            if selectedTab == nil {
                selectedTab = items.first?.type
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            updateLocalizedData()
        }
        .onDisappear {
            saveCompletedItems()
        }
    }
    
    // Adaptive functions
    private func adaptiveDividerPadding(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.height <= 667 ? 4 : 8
    }
    
    private func adaptiveListSpacing(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.height <= 667 ? 8 : 16
    }
    
    private func adaptiveVerticalPadding(_ geometry: GeometryProxy) -> CGFloat {
        geometry.size.height <= 667 ? 8 : 16
    }
    
    // Helper functions
    private func updateLocalizedData() {
        items = [
            ListItemView(type: .BathroomItems, title: "bathroom", subtitle: "bathroom_essentials"),
            ListItemView(type: .KitchenItems, title: "kitchen", subtitle: "kitchen_essentials"),
            ListItemView(type: .ClothesItems, title: "clothes", subtitle: "clothing_essentials"),
            ListItemView(type: .UsefulItems, title: "useful", subtitle: "useful_items"),
            ListItemView(type: .ElectronicsItems, title: "electronics", subtitle: "electronics_items"),
            ListItemView(type: .CampingItems, title: "camping", subtitle: "camping_essentials"),
            ListItemView(type: .ToolsItems, title: "tools", subtitle: "tools_equipment"),
            ListItemView(type: .OtherItems, title: "other", subtitle: "other_items")
        ]
    }
    
    private func loadCompletedItems() {
        guard let data = UserDefaults.standard.data(forKey: "CompletedItems"),
              let decoded = try? JSONDecoder().decode([String: Set<Int>].self, from: data) else {
            return
        }
        completedItems = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
            guard let type = ListItem(rawValue: key) else { return nil }
            return (type, value)
        })
    }
    
    private func saveCompletedItems() {
        let encodableDict = Dictionary(uniqueKeysWithValues: completedItems.map { (key, value) in
            (key.rawValue, value)
        })
        guard let data = try? JSONEncoder().encode(encodableDict) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "CompletedItems")
    }
    
    func getListItems(for type: ListItem) -> [String] {
        switch type {
        case .BathroomItems: return getBathroomItems()
        case .KitchenItems: return getKitchenItems()
        case .ClothesItems: return getClothesItems()
        case .UsefulItems: return getUsefulItems()
        case .ElectronicsItems: return getElectronicsItems()
        case .CampingItems: return getCampingItems()
        case .ToolsItems: return getToolsItems()
        case .OtherItems: return getOtherItems()
        }
    }
}

struct CategoryButton: View {
    let listItem: ListItemView
    @Binding var selectedTab: ListItem?
    let geometry: GeometryProxy
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(listItem.title.appLocalized)
                .font(.system(size: geometry.size.width <= 375 ? 13 : 15))
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, geometry.size.width <= 375 ? 12 : 16)
                .background(
                    Capsule()
                        .fill(selectedTab == listItem.type ?
                              Color.white.opacity(0.3) :
                                Color.white.opacity(0.15))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .id(listItem.type.rawValue)
    }
}

struct CategorySection: View {
    let listItem: ListItemView
    let items: [String]
    @Binding var completedItems: [ListItem: Set<Int>]
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading, spacing: geometry.size.height <= 667 ? 8 : 12) {
            Text(listItem.title.appLocalized)
                .font(.system(size: geometry.size.height <= 667 ? 18 : 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, geometry.size.width <= 375 ? 12 : 16)
            
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ChecklistItem(
                    item: item,
                    isCompleted: completedItems[listItem.type]?.contains(index) ?? false,
                    geometry: geometry,
                    toggleAction: {
                        toggleCompletion(itemIndex: index)
                    }
                )
            }
        }
        .id(listItem.type.rawValue)
        .padding(.horizontal, geometry.size.width <= 375 ? 12 : 16)
    }
    
    private func toggleCompletion(itemIndex: Int) {
        var completedSet = completedItems[listItem.type] ?? Set<Int>()
        if completedSet.contains(itemIndex) {
            completedSet.remove(itemIndex)
        } else {
            completedSet.insert(itemIndex)
        }
        completedItems[listItem.type] = completedSet
        HapticManager.shared.impact(style: .light)
    }
}

struct ChecklistItem: View {
    let item: String
    let isCompleted: Bool
    let geometry: GeometryProxy
    let toggleAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: toggleAction) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .black)
                    .font(.system(size: geometry.size.width <= 375 ? 18 : 20))
            }
            .padding(.leading, geometry.size.width <= 375 ? 12 : 16)
            
            Text(item.appLocalized)
                .foregroundColor(.black)
                .font(.system(size: geometry.size.width <= 375 ? 14 : 16))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer()
        }
        .frame(height: geometry.size.height <= 667 ? 36 : 44)
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct TravelChecklist_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TravelChecklist()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE")
            
            TravelChecklist()
                .previewDevice(PreviewDevice(rawValue: "iPhone 13"))
                .previewDisplayName("iPhone 13")
            
            TravelChecklist()
                .previewDevice(PreviewDevice(rawValue: "iPhone 13 Pro Max"))
                .previewDisplayName("iPhone 13 Pro Max")
        }
    }
}
