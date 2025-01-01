import SwiftUI

struct ToastView: View {
    let achievement: Achievement
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading) {
                Text("Nowe osiągnięcie!")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(achievement.title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isShowing = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color(hex: "#29606D").opacity(0.95))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 10)
        .padding(.horizontal)
    }
}
