import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    let authenticationService = AuthenticationService.shared

    var body: some View {
        VStack {
            Text("registration_title".appLocalized) 
                .font(.largeTitle)
                .foregroundColor(currentTheme.primaryText)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(currentTheme.error)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            TextField("email_placeholder".appLocalized, text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            
            SecureField("password_placeholder".appLocalized, text: $password)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            
            SecureField("confirm_password_placeholder".appLocalized, text: $confirmPassword)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            
            Button(action: registerUser) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("register_button".appLocalized)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentTheme.primary)
                        .foregroundColor(currentTheme.lightText)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)
            
            Spacer()
        }
        .padding()
        .background(Color(currentTheme.background).edgesIgnoringSafeArea(.all))
        .navigationTitle("registration_title".appLocalized)
    }
    
    private var currentTheme: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    private func registerUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "error_missing_email_password".appLocalized
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "error_passwords_mismatch".appLocalized
            return
        }
        
        isLoading = true
        authenticationService.registerUser(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = "registration_error".appLocalized + ": \(error.localizedDescription)"
            }
        }
    }
}
