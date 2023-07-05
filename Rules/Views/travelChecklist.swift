import SwiftUI
import Foundation

struct TravelChecklist: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedTab: ListItem?
    @State private var scrollToTop: Bool = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    // Tu dodajemy słownik do przechowywania zrobionych elementów dla każdego typu
    @State private var completedItems: [ListItem: [String]] = [:]
    
    let listData: [ListItemView] = [
        ListItemView(type: .BathroomItems, title: "Bathroom", subtitle: "Bathroom Essentials"),
        ListItemView(type: .KitchenItems, title: "Kitchen", subtitle: "Kitchen Essentials"),
        ListItemView(type: .ClothesItems, title: "Clothes", subtitle: "Clothing Essentials"),
        ListItemView(type: .UsefulItems, title: "Useful", subtitle: "Useful Items"),
        ListItemView(type: .ElectronicsItems, title: "Electronics", subtitle: "Electronics"),
        ListItemView(type: .CampingItems, title: "Camping", subtitle: "Camping Essentials"),
        ListItemView(type: .ToolsItems, title: "Tools", subtitle: "Tools and Equipment"),
        ListItemView(type: .OtherItems, title: "Other", subtitle: "Other Items")
    ]
    
    init() {
        loadCompletedItems()
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(listData) { listItem in
                        Button(action: {
                            selectedTab = listItem.type
                            scrollToTop = true
                        }) {
                            Text(listItem.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(selectedTab == listItem.type ? (Color(hex: "#29606D")) : Color.gray.opacity(0.5))
                                        .foregroundColor(.white)

                                        )
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        selectedTab = listItem.type
                                        scrollToTop = true
                                    }
                                }
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
                        ForEach(listData) { listItem in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(listItem.title)
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
                                        Text(item)
                                        Spacer()
                                    }
                                    .padding(.leading, 10)
                                    .font(.headline)
                                    .frame(height: 40.0)
                                    .background(Color(hex: "#29606D"))
                                    .foregroundColor(Color.white)
                                    .cornerRadius(15)
                                    .frame(maxWidth: 340)
                                    

                                    
                                }
                            }
//                                .background(Color.white.opacity(0.5))
//                                .cornerRadius(15)

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
        }
        .onDisappear {
            saveCompletedItems()
        }
    }
    
    func getListItems(for type: ListItem) -> [String] {
        switch type {
        case .BathroomItems:
            return BathroomItems
        case .KitchenItems:
            return KitchenItems
        case .ClothesItems:
            return ClothesItems
        case .UsefulItems:
            return UsefulItems
        case .ElectronicsItems:
            return ElectronicsItems
        case .CampingItems:
            return CampingItems
        case .ToolsItems:
            return ToolsItems
        case .OtherItems:
            return OtherItems
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
        guard let selectedItem = listData.last(where: { $0.type.rawValue == selectedTab?.rawValue }) else {
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

struct TravelChecklist_Previews: PreviewProvider {
    static var previews: some View {
        TravelChecklist()
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
