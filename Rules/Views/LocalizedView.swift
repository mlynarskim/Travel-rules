import SwiftUI

struct LocalizedView<Content: View>: View {
    @StateObject private var languageManager = LanguageManager.shared
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}
