import SwiftUI

struct AchievementsView: View {
   @Environment(\.dismiss) private var dismiss
   @Environment(\.colorScheme) private var colorScheme
   @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
   @StateObject private var achievementManager = AchievementManager()
   
   private var theme: ThemeColors {
       switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
       case .classic: return ThemeColors.classicTheme
       case .mountain: return ThemeColors.mountainTheme
       case .beach: return ThemeColors.beachTheme
       case .desert: return ThemeColors.desertTheme
       case .forest: return ThemeColors.forestTheme
       }
   }
   
   var body: some View {
       NavigationView {
           ZStack {
               Color(theme.background)
                   //.edgesIgnoringSafeArea(.all)
                   .ignoresSafeArea()
               List {
                   ForEach(achievementManager.achievements) { achievement in
                       HStack {
                           Image(systemName: achievement.icon)
                               .foregroundColor(achievement.isUnlocked ?
                                              theme.accent :
                                              .gray.opacity(0.5))
                               .font(.title2)
                               .frame(width: 40)
                               .scaleEffect(achievement.isUnlocked ? 1.1 : 1.0)
                               .animation(.easeInOut(duration: 0.3), value: achievement.isUnlocked)
                           
                           VStack(alignment: .leading, spacing: 4) {
                               Text(achievement.title)
                                   .font(.headline)
                                   .foregroundColor(theme.primaryText)
                               
                               Text(achievement.description)
                                   .font(.subheadline)
                                   .foregroundColor(theme.secondaryText)
                           }
                           
                           Spacer()
                           
                           if achievement.isUnlocked {
                               Image(systemName: "checkmark.circle.fill")
                                   .foregroundColor(theme.success)
                           }
                       }
                       .padding(.vertical, 8)
                       .opacity(achievement.isUnlocked ? 1 : 0.6)
                   }
               }
               .listStyle(InsetGroupedListStyle())
           }
           .navigationTitle("Osiągnięcia")
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
               ToolbarItem(placement: .navigationBarTrailing) {
                   Button(action: {
                       dismiss()
                   }) {
                       Image(systemName: "xmark.circle.fill")
                           .foregroundColor(Color(.systemGray3))
                   }
               }
           }
       }
   }
}
