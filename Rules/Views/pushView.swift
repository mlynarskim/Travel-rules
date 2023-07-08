import SwiftUI

struct pushView: View {
    @State private var notificationEnabled = false
    
    var body: some View {
        VStack {
            Text("Notification Settings")
                .font(.title)
                .padding()
            
            Toggle("Enable Notifications", isOn: $notificationEnabled)
                .padding()
            
            Spacer()
            
            Button(action: {
                // Akcja dla przycisku "Save"
                // Możesz dodać kod obsługujący zapisanie ustawień powiadomień
                // np. zapisanie wartości `notificationEnabled` do UserDefaults
            }) {
                Text("Save")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}
