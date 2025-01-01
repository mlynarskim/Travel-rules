import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var achievementManager = AchievementManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#29606D").opacity(0.1).edgesIgnoringSafeArea(.all)
                
                List {
                    
                    ForEach(achievementManager.achievements) { achievement in
                        HStack {
                            Image(systemName: achievement.icon)
                                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                                .font(.title2)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(achievement.title)
                                    .font(.headline)
                                Text(achievement.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if achievement.isUnlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 8)
                        .opacity(achievement.isUnlocked ? 1 : 0.6)
                        .animation(.spring(), value: achievement.isUnlocked)
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
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                            print("Liczba osiągnięć: \(achievementManager.achievements.count)")
                        }

        }
    }
}
