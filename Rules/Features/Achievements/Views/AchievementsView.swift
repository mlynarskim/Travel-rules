import SwiftUI

struct AchievementsView: View {
   @Environment(\.dismiss) private var dismiss
   @Environment(\.colorScheme) private var colorScheme
   @StateObject private var achievementManager = AchievementManager()
   
   var body: some View {
       NavigationView {
           ZStack {
               Color(hex: "#29606D")
                   .opacity(colorScheme == .dark ? 0.15 : 0.1)
                   .edgesIgnoringSafeArea(.all)
               
               List {
                   ForEach(achievementManager.achievements) { achievement in
                       HStack {
                           Image(systemName: achievement.icon)
                               .foregroundColor(achievement.isUnlocked ?
                                              achievement.themeColor :
                                              .gray.opacity(0.5))
                               .font(.title2)
                               .frame(width: 40)
                           
                           VStack(alignment: .leading, spacing: 4) {
                               Text(achievement.title)
                                   .font(.headline)
                                   .foregroundColor(colorScheme == .dark ? .white : .primary)
                               
                               Text(achievement.description)
                                   .font(.subheadline)
                                   .foregroundColor(.secondary)
                           }
                           
                           Spacer()
                           
                           if achievement.isUnlocked {
                               Image(systemName: "checkmark.circle.fill")
                                   .foregroundColor(achievement.themeColor)
                           }
                       }
                       .padding(.vertical, 8)
                       .opacity(achievement.isUnlocked ? 1 : 0.6)
                       .animation(.spring(), value: achievement.isUnlocked)
                   }
               }
               .listStyle(InsetGroupedListStyle())
           }
           .navigationTitle(NSLocalizedString("achievements.title", comment: ""))
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
           .onAppear {
               print("Achievements count: \(achievementManager.achievements.count)")
           }
       }
   }
}

