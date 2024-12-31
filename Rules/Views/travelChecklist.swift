import SwiftUI
import Foundation

struct TravelChecklist: View {
   @State private var scrollOffset: CGFloat = 0
   @State private var selectedTab: ListItem?
   @State private var scrollToTop: Bool = false
   @State private var scrollViewProxy: ScrollViewProxy? = nil
   @State private var items: [ListItemView] = []
   @StateObject private var languageManager = LanguageManager.shared
   @State private var completedItems: [ListItem: Set<Int>] = [:]
   @AppStorage("isDarkMode") var isDarkMode = false
   
   init() {
       loadCompletedItems()
   }
   
   var body: some View {
       NavigationView {
           ZStack {
               Image(isDarkMode ? "imageDark" : "Image")
                   .resizable()
                   .scaledToFill()
                   .edgesIgnoringSafeArea(.all)
               
               VStack {
                   ScrollViewReader { horizontalProxy in
                       ScrollView(.horizontal, showsIndicators: false) {
                           HStack(spacing: 16) {
                               ForEach(items) { listItem in
                                   Button(action: {
                                       selectedTab = listItem.type
                                       scrollToTop = true
                                       DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                           withAnimation {
                                               horizontalProxy.scrollTo(listItem.type.rawValue, anchor: .leading)
                                           }
                                       }
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
                                   .id(listItem.type.rawValue)
                               }
                           }
                           .padding(.top, 60)
                           .padding(.horizontal, 16)
                           .onChange(of: scrollOffset) { newValue in
                               updateSelectedTab()
                           }
                       }
                   }
                   
                   Divider()
                   
                   ScrollViewReader { scrollViewProxy in
                       ScrollView {
                           VStack(spacing: 10) {
                               ForEach(items) { listItem in
                                   VStack(alignment: .leading, spacing: 10) {
                                       Text(listItem.title.appLocalized)
                                           .font(.title)
                                           .fontWeight(.bold)
                                           .padding(.leading, 16)
                                           .padding(.bottom, 5)
                                       
                                       let items = getListItems(for: listItem.type)
                                       ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                           HStack {
                                               Button(action: {
                                                   toggleItemCompletion(listItem: listItem, itemIndex: index)
                                               }) {
                                                   Image(systemName: itemIsCompleted(listItem: listItem, itemIndex: index) ? "checkmark.circle.fill" : "circle")
                                                       .foregroundColor(itemIsCompleted(listItem: listItem, itemIndex: index) ? .green : .white)
                                                       .padding(.trailing, 5)
                                               }
                                               Text(item.appLocalized)
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
               .safeAreaInset(edge: .top) {
                   Color.clear.frame(height: 20)
               }
           }
       }
       .navigationBarHidden(true)
       .onAppear {
           loadCompletedItems()
           updateLocalizedData()
       }
       .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
           updateLocalizedData()
           if let selectedTab = selectedTab {
               self.selectedTab = selectedTab
           }
       }
       .onDisappear {
           saveCompletedItems()
       }
   }
   
   func itemIsCompleted(listItem: ListItemView, itemIndex: Int) -> Bool {
       return completedItems[listItem.type]?.contains(itemIndex) ?? false
   }
   
   func toggleItemCompletion(listItem: ListItemView, itemIndex: Int) {
       var completedSet = completedItems[listItem.type] ?? Set<Int>()
       if completedSet.contains(itemIndex) {
           completedSet.remove(itemIndex)
       } else {
           completedSet.insert(itemIndex)
       }
       completedItems[listItem.type] = completedSet
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
   
   func updateSelectedTab() {
       guard let selectedItem = items.last(where: { $0.type.rawValue == selectedTab?.rawValue }) else {
           return
       }
       selectedTab = selectedItem.type
   }
   
   func loadCompletedItems() {
       guard let data = UserDefaults.standard.data(forKey: "CompletedItems"),
             let decoded = try? JSONDecoder().decode([String: Set<Int>].self, from: data) else {
           return
       }
       completedItems = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
           guard let type = ListItem(rawValue: key) else { return nil }
           return (type, value)
       })
   }
   
   func saveCompletedItems() {
       let encodableDict = Dictionary(uniqueKeysWithValues: completedItems.map { (key, value) in
           (key.rawValue, value)
       })
       guard let data = try? JSONEncoder().encode(encodableDict) else {
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

struct travelChecklist: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.colorScheme, .light)
    }
}
