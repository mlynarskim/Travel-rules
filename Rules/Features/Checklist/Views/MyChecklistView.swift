import SwiftUI
import Darwin
import UIKit

// MARK: - Kompatybilne onChange
extension View {
    @ViewBuilder
    func onChangeCompat<V: Equatable>(_ value: V, action: @escaping () -> Void) -> some View {
        if #available(iOS 17, *) {
            self.onChange(of: value) { _, _ in action() }
        } else {
            self.onChange(of: value) { _ in action() }
        }
    }
}

// MARK: - Model
struct TravelItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isCompleted: Bool = false
    
    init(id: UUID = UUID(), name: String, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
    }
}

// MARK: - Widok główny
struct MyChecklistView: View {
    @State private var travelItems: [TravelItem] = []
    @State private var newItemName: String = ""
    @State private var selectedTab: Int = 0
    @State private var showExportSheet = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var keyboard = KeyboardResponder()
    @Environment(\.scenePhase) private var scenePhase
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:  return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach:    return ThemeColors.beachTheme
        case .desert:   return ThemeColors.desertTheme
        case .forest:   return ThemeColors.forestTheme
        case .autumn:   return ThemeColors.autumnTheme
        case .spring:   return ThemeColors.springTheme
        case .winter:   return ThemeColors.winterTheme
        case .summer:   return ThemeColors.summerTheme


        }
    }

    // MARK: - Background Image
    private var backgroundImageView: some View {
        let imageName: String
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:   imageName = isDarkMode ? "classic-bg-dark" : "theme-classic-preview"
        case .mountain:  imageName = isDarkMode ? "mountain-bg-dark" : "theme-mountain-preview"
        case .beach:     imageName = isDarkMode ? "beach-bg-dark" : "theme-beach-preview"
        case .desert:    imageName = isDarkMode ? "desert-bg-dark" : "theme-desert-preview"
        case .forest:    imageName = isDarkMode ? "forest-bg-dark" : "theme-forest-preview"
        case .autumn:    imageName = isDarkMode ? "autumn-bg-dark" : "theme-autumn-preview"
        case .spring:    imageName = isDarkMode ? "spring-bg-dark" : "theme-spring-preview"
        case .winter:   imageName = isDarkMode ? "winter-bg-dark" : "theme-winter-preview"
        case .summer:   imageName = isDarkMode ? "summer-bg-dark" : "theme-summer-preview"

        }
        return Image(imageName)
            .resizable()
            .ignoresSafeArea()
    }

    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundImageView
                
                VStack(spacing: 16) {
                    Spacer().frame(height: 40)
                    
                    SegmentedPicker(selectedTab: $selectedTab, themeColors: themeColors)
                        .padding(.horizontal)

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
            }
            .navigationBarItems(trailing:
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    showExportSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: isSmallDevice ? 18 : 20))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            )
            .sheet(isPresented: $showExportSheet) {
                ExportView(
                    items: travelItems.map { $0.name },
                    themeColors: themeColors
                )
            }
            .onAppear(perform: loadItems)
            .onDisappear(perform: saveItems)
            .onChangeCompat(travelItems) { saveItems() }
            .onChangeCompat(scenePhase) {
                if scenePhase == .background { saveItems() }
            }
        }
    }

    // MARK: - Persistence
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

// MARK: - ChecklistItemRow
struct ChecklistItemRow: View {
    @Binding var item: TravelItem
    let themeColors: ThemeColors
    let isSmallDevice: Bool
    let deleteAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation { item.isCompleted.toggle() }
                HapticManager.shared.impact(style: .light)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? themeColors.success : themeColors.primaryText)
                    .font(.system(size: isSmallDevice ? 18 : 20))
            }
            .padding(.leading, isSmallDevice ? 12 : 16)
            .buttonStyle(.plain)
            
            Text(item.name)
                .foregroundColor(themeColors.lightText)
                .font(.system(size: isSmallDevice ? 14 : 16))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .strikethrough(item.isCompleted, color: themeColors.lightText)
            
            Spacer()
            
            Button(action: deleteAction) {
                Image(systemName: "trash")
                    .foregroundColor(themeColors.error)
                    .font(.system(size: isSmallDevice ? 14 : 16))
            }
            .padding(.trailing, 8)
            .buttonStyle(.plain)
        }
        .frame(height: isSmallDevice ? 32 : 36)
        .background(themeColors.primary)
        .cornerRadius(12)
        .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - ChecklistContentView
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
                            deleteAction: { deleteItem(item) }
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

// MARK: - AddItemView i AddButtonStyle
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
                .buttonStyle(AddButtonStyle(themeColors: themeColors, isSmallDevice: isSmallDevice)) // NIE dodajemy .buttonStyle(.plain), aby nie nadpisać niestandardowego AddButtonStyle
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

// MARK: - SegmentedPicker
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

// MARK: - ExportView (z blokadą Premium dla statycznych PDF-ów)
struct ExportView: View {
    let items: [String]
    let themeColors: ThemeColors
    @Environment(\.dismiss) private var dismiss

    @State private var sharePayload: SharePayload?
    @State private var showingError = false

    @AppStorage("hasPremium") private var hasPremium: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ExportButtonView(
                    items: items,
                    title: "myTravelList".appLocalized,
                    category: "userChecklist".appLocalized,
                    fileName: "My Travel Checklist.pdf"
                )
                .padding(.horizontal)
                .buttonStyle(.plain)

                PremiumLockedButton(
                    hasPremium: hasPremium,
                    title: "Travel Rules Checklist English",
                    themeColors: themeColors
                ) { exportBundle(named: "Travel Rules Checklist English") }
                .padding(.horizontal)
                .buttonStyle(.plain)

                PremiumLockedButton(
                    hasPremium: hasPremium,
                    title: "Travel Rules Checklist Polish",
                    themeColors: themeColors
                ) { exportBundle(named: "Travel Rules Checklist Polish") }
                .padding(.horizontal)
                .buttonStyle(.plain)

                PremiumLockedButton(
                    hasPremium: hasPremium,
                    title: "Travel Rules Checklist Spanish",
                    themeColors: themeColors
                ) { exportBundle(named: "Travel Rules Checklist Spanish") }
                .padding(.horizontal)
                .buttonStyle(.plain)

                Spacer()
            }
            .background(Color(themeColors.background).ignoresSafeArea())
            .navigationTitle("export_pdf".appLocalized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("exit".appLocalized) { dismiss() }
                        .foregroundColor(themeColors.primaryText)
                        .buttonStyle(.plain)
                }
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(activityItems: payload.items)
            }
            .alert("Export error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
                .buttonStyle(.plain)
            } message: {
                Text("error_pdf".appLocalized)
            }
        }
    }

    @MainActor
    private func exportBundle(named resource: String) {
        guard let fileURL = Bundle.main.url(forResource: resource, withExtension: "pdf") else {
            showingError = true
            return
        }
        sharePayload = SharePayload(items: [fileURL])
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}


// MARK: - PremiumLockedButton (przycisk z paywallem)
struct PremiumLockedButton: View {
    let hasPremium: Bool
    let title: String
    let themeColors: ThemeColors
    let action: () -> Void

    @State private var showLockedAlert = false

    var body: some View {
        Button(action: {
            if hasPremium {
                action()
            } else {
                showLockedAlert = true
            }
        }) {
            HStack {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if !hasPremium {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                        Text("premium".appLocalized)
                    }
                    .font(.system(size: 12, weight: .bold))
                }
            }
            .padding()
            .background(hasPremium ? themeColors.accent : themeColors.accent.opacity(0.6))
            .foregroundColor(themeColors.lightText)
            .cornerRadius(10)
            .shadow(color: themeColors.cardShadow, radius: 5)
            .buttonStyle(.plain)
        }
        .alert("premium_required_title".appLocalized, isPresented: $showLockedAlert) {
            Button("ok".appLocalized, role: .cancel) { }
            .buttonStyle(.plain)
        } message: {
            Text("premium_required_message".appLocalized)
        }
    }
}
