import SwiftUI
import Foundation

struct TravelChecklist: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedTab: ListItem?
    @State private var scrollToTop: Bool = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var items: [ListItemView] = []
    @StateObject private var languageManager = LanguageManager.shared
    @State private var completedItems: [ListItem: [String]] = [:]
    
    init() {
        loadCompletedItems()
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { listItem in
                        Button(action: {
                            selectedTab = listItem.type
                            scrollToTop = true
                        }) {
                            Text(listItem.title.appLocalized)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(selectedTab == listItem.type ? (Color(hex: "#29606D")) : Color.gray.opacity(0.5))
                                )
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
                .onChange(of: scrollOffset) { newValue in
                    updateSelectedTab()
                }
            }
            
            Divider()
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(items) { listItem in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(listItem.title.appLocalized) // Dodano .appLocalized
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.leading, 16)
                                    .padding(.bottom, 5)
                                
                                ForEach(getListItems(for: listItem.type), id: \.self) { item in
                                    HStack {
                                        Button(action: {
                                            toggleItemCompletion(listItem: listItem, itemTitle: item)
                                        }) {
                                            Image(systemName: itemIsCompleted(listItem: listItem, itemTitle: item) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(itemIsCompleted(listItem: listItem, itemTitle: item) ? .green : .white)
                                                .padding(.trailing, 5)
                                        }
                                        Text(item.appLocalized) // Dodano .appLocalized
                                        Spacer()
                                    }
                                    .padding(.leading, 10)
                                    .font(.headline)
                                    .frame(height: 40.0)
                                    .background(Color(hex: "#29606D"))
                                    .foregroundColor(Color.white)
                                    .cornerRadius(15)
                                    .frame(maxWidth: 340)
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                }
                            }
                            .id(listItem.type.rawValue)
                            .onChange(of: selectedTab) { newValue in
                                if newValue == listItem.type && scrollToTop {
                                    withAnimation {
                                        scrollViewProxy.scrollTo(listItem.type.rawValue, anchor: .top)
                                    }
                                    scrollToTop = false
                                }
                            }
                        }
                    }
                    .padding()
                }
                .overlay(
                    GeometryReader { proxy in
                        Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                    }
                )
                .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
        }
        .onAppear {
            loadCompletedItems()
            updateLocalizedData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            updateLocalizedData()
        }
        .onDisappear {
            saveCompletedItems()
        }
    }
    
    private func updateLocalizedData() {
        items = [
            ListItemView(type: .BathroomItems, title: "bathroom".appLocalized, subtitle: "bathroom_essentials".appLocalized),
            ListItemView(type: .KitchenItems, title: "kitchen".appLocalized, subtitle: "kitchen_essentials".appLocalized),
            ListItemView(type: .ClothesItems, title: "clothes".appLocalized, subtitle: "clothing_essentials".appLocalized),
            ListItemView(type: .UsefulItems, title: "useful".appLocalized, subtitle: "useful_items".appLocalized),
            ListItemView(type: .ElectronicsItems, title: "electronics".appLocalized, subtitle: "electronics_items".appLocalized),
            ListItemView(type: .CampingItems, title: "camping".appLocalized, subtitle: "camping_essentials".appLocalized),
            ListItemView(type: .ToolsItems, title: "tools".appLocalized, subtitle: "tools_equipment".appLocalized),
            ListItemView(type: .OtherItems, title: "other".appLocalized, subtitle: "other_items".appLocalized)
        ]
    }
    
    func getListItems(for type: ListItem) -> [String] {
        switch type {
        case .BathroomItems:
            return getBathroomItems()
        case .KitchenItems:
            return getKitchenItems()
        case .ClothesItems:
            return getClothesItems()
        case .UsefulItems:
            return getUsefulItems()
        case .ElectronicsItems:
            return getElectronicsItems()
        case .CampingItems:
            return getCampingItems()
        case .ToolsItems:
            return getToolsItems()
        case .OtherItems:
            return getOtherItems()
        }
    }
    
    func itemIsCompleted(listItem: ListItemView, itemTitle: String) -> Bool {
        return completedItems[listItem.type]?.contains(itemTitle) ?? false
    }
    
    func toggleItemCompletion(listItem: ListItemView, itemTitle: String) {
        if var completedItemsList = completedItems[listItem.type] {
            if completedItemsList.contains(itemTitle) {
                completedItemsList.removeAll { $0 == itemTitle }
            } else {
                completedItemsList.append(itemTitle)
            }
            completedItems[listItem.type] = completedItemsList
        } else {
            completedItems[listItem.type] = [itemTitle]
        }
    }
    
    func updateSelectedTab() {
        guard let selectedItem = items.last(where: { $0.type.rawValue == selectedTab?.rawValue }) else {
            return
        }
        selectedTab = selectedItem.type
    }
    
    func loadCompletedItems() {
        guard let data = UserDefaults.standard.data(forKey: "CompletedItems"),
              let completedItems = try? JSONDecoder().decode([ListItem: [String]].self, from: data) else {
            return
        }
        self.completedItems = completedItems
    }
    
    func saveCompletedItems() {
        guard let data = try? JSONEncoder().encode(completedItems) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "CompletedItems")
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
