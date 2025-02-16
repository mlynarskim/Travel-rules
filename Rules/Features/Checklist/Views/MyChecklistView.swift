import SwiftUI

struct TravelItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isCompleted = false

    init(name: String) {
        self.name = name
    }
}

struct MyChecklistView: View {
    @State private var travelItems: [TravelItem] = []
    @State private var newItemName: String = ""
    @State private var selectedTab: Int = 0
    @State private var showExportSheet = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var keyboard = KeyboardResponder()
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:  return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach:    return ThemeColors.beachTheme
        case .desert:   return ThemeColors.desertTheme
        case .forest:   return ThemeColors.forestTheme
        }
    }
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    BackgroundView(selectedTheme: selectedTheme, isDarkMode: isDarkMode)
                    
                    VStack(spacing: 16) {
                        Spacer()
                            .frame(height: 40)
                        
                        SegmentedPicker(selectedTab: $selectedTab, themeColors: themeColors)
                            .padding(.horizontal)
                            .padding(.top, 80)
                        
                        if selectedTab == 0 {
                            ChecklistContentView(
                                travelItems: $travelItems,
                                newItemName: $newItemName,
                                themeColors: themeColors,
                                isSmallDevice: isSmallDevice
                            )
                        } else {
                            TravelChecklist()
                        }
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showExportSheet) {
                ExportView(items: travelItems.map { $0.name }, themeColors: themeColors)
            }
            .onAppear(perform: loadItems)
            .onDisappear(perform: saveItems)
            .navigationBarItems(trailing:
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    showExportSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: isSmallDevice ? 18 : 20))
                        .foregroundColor(.white)
                }
            )
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "travelItems"),
           let decoded = try? JSONDecoder().decode([TravelItem].self, from: data) {
            travelItems = decoded
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(travelItems) {
            UserDefaults.standard.set(encoded, forKey: "travelItems")
        }
    }
}

struct ChecklistItemRow: View {
    @Binding var item: TravelItem
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let deleteAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    item.isCompleted.toggle()
                }
                HapticManager.shared.impact(style: .light)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? themeColors.success : .white)
                    .font(.system(size: isSmallDevice ? 16 : 18))
            }
            
            Text(item.name)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .gray : .white) 
                .font(.system(size: isSmallDevice ? 16 : 18))
                .lineLimit(1)
            
            Spacer()
            
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .foregroundColor(themeColors.error)
                    .font(.system(size: isSmallDevice ? 14 : 16))
            }
        }
        .padding()
        .frame(height: isSmallDevice ? 36 : 40)
        .background(themeColors.primary)
        .cornerRadius(15)
        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
    }
}

struct BackgroundView: View {
    let selectedTheme: String
    let isDarkMode: Bool
    
    var body: some View {
        let imageName = "\(selectedTheme)-bg\(isDarkMode ? "-dark" : "")"
        Image(imageName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

struct SegmentedPicker: View {
    @Binding var selectedTab: Int
    let themeColors: ThemeColors
    
    var body: some View {
        Picker("", selection: $selectedTab) {
            Text("my_checklist".appLocalized).tag(0)
            Text("packing_list".appLocalized).tag(1)
        }
        .pickerStyle(.segmented)
        .tint(themeColors.primary)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeColors.primary.opacity(0.7))
        )
        .frame(height: 40)
    }
}

struct ChecklistContentView: View {
    @Binding var travelItems: [TravelItem]
    @Binding var newItemName: String
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    
    var body: some View {
        VStack(spacing: isSmallDevice ? 8 : 12) {
            AddItemView(
                newItemName: $newItemName,
                themeColors: themeColors,
                isSmallDevice: isSmallDevice,
                addAction: addItem
            )
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($travelItems) { $item in
                        ChecklistItemRow(
                            item: $item,
                            themeColors: themeColors,
                            isSmallDevice: isSmallDevice,
                            deleteAction: {
                                deleteItem(item)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .background(Color.clear)
        }
    }
    
    private func addItem() {
        guard !newItemName.isEmpty else { return }
        withAnimation(.spring()) {
            travelItems.append(TravelItem(name: newItemName))
            newItemName = ""
        }
        HapticManager.shared.impact(style: .medium)
    }
    
    private func deleteItem(_ item: TravelItem) {
        withAnimation(.easeOut) {
            travelItems.removeAll { $0.id == item.id }
        }
        HapticManager.shared.notification(type: .success)
    }
}

struct AddItemView: View {
    @Binding var newItemName: String
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let addAction: () -> Void
    
    var body: some View {
        HStack {
            TextField("enter_new_item".appLocalized, text: $newItemName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: isSmallDevice ? 14 : 16))
                .submitLabel(.done)
                .onSubmit(addAction)
            
            Button("add".appLocalized, action: addAction)
                .buttonStyle(AddButtonStyle(themeColors: themeColors, isSmallDevice: isSmallDevice))
        }
        .padding(.horizontal)
        .padding(.vertical, isSmallDevice ? 8 : 10)
    }
}

struct AddButtonStyle: ButtonStyle {
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isSmallDevice ? 14 : 16, weight: .semibold))
            .frame(width: isSmallDevice ? 70 : 80, height: isSmallDevice ? 32 : 35)
            .background(themeColors.primary)
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}



struct ExportView: View {
    let items: [String]
    let themeColors: ThemeColors
    @Environment(\ .dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("".appLocalized)
                    .font(.title)
                    .foregroundColor(themeColors.primaryText)
                    .padding()
                
                // Przycisk eksportu My Checklist
                ExportButtonView(
                    items: items,
                    title: "myTravelList".appLocalized,
                    category: "userChecklist".appLocalized
                )
                .padding()

                // Nowy przycisk eksportu gotowego pliku PDF Travel Checklist
                Button(action: exportStaticTravelChecklist) {
                    HStack {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 18))
                        Text(LocalizedStringKey("travel.checklist.button"))
                    }
                    .padding()
                    .background(themeColors.accent)
                    .foregroundColor(themeColors.lightText)
                    .cornerRadius(10)
                    .shadow(color: themeColors.cardShadow, radius: 5)
                }
                .padding()

                Spacer()
            }
            .background(Color(themeColors.background).ignoresSafeArea())
            .navigationTitle("export_pdf".appLocalized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("exit".appLocalized) {
                        dismiss()
                    }
                    .foregroundColor(themeColors.primaryText)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: shareItems)
            }
            .alert("Export error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("error_pdf".appLocalized)
            }
        }
    }
    
    private func exportStaticTravelChecklist() {
        guard let fileURL = Bundle.main.url(forResource: "Travel checklist", withExtension: "pdf") else {
            showingError = true
            return
        }
        
        shareItems = [fileURL]
        showShareSheet = true
    }
}
