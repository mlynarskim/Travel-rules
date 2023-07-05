import SwiftUI

@main
struct RulesApp: App {
    @AppStorage("isDarkMode") var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
