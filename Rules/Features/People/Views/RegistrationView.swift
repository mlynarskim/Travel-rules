import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    // Dane użytkownika – zmienne stanu
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""       // opcjonalne
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dane osobowe")) {
                    TextField("Nazwa użytkownika", text: $username)
                        .autocapitalization(.none)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefon (opcjonalnie)", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Hasło")) {
                    SecureField("Hasło", text: $password)
                    SecureField("Potwierdź hasło", text: $confirmPassword)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Zarejestruj się") {
                        registerUser()
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Rejestracja")
        }
    }
    
    private func registerUser() {
        // Walidacja danych
        guard !username.isEmpty else {
            errorMessage = "Nazwa użytkownika jest wymagana."
            return
        }
        guard !email.isEmpty else {
            errorMessage = "Email jest wymagany."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Hasło jest wymagane."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Hasła nie są zgodne."
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // Rejestracja użytkownika przy użyciu Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            isLoading = false
            if let error = error {
                errorMessage = "Błąd rejestracji: \(error.localizedDescription)"
            } else if let uid = authResult?.user.uid {
                // Tworzymy nowy profil użytkownika – tutaj możesz rozszerzyć model o pole phone
                let newProfile = UserProfile(
                    id: uid,
                    name: username,
                    avatarUrl: nil,            // Awatar pomijamy
                    description: nil,          // Opis pomijamy
                    lastActiveTime: Date(),
                    helpProvidedCount: 0,
                    activeDaysCount: 0,
                    thanksReceivedCount: 0,
                    helpOffered: [],
                    status: .available,        // Domyślny status
                    category: .social,         // Domyślna kategoria
                    distance: 0.0,
                    shareLevel: .approximate
                )
                
                // Jeśli chcesz zapisać numer telefonu w profilu, rozważ dodanie pola phone do modelu UserProfile
                // i ustawienie go tutaj, np. phone: phone.isEmpty ? nil : phone
                
                let db = Firestore.firestore()
                do {
                    try db.collection("users").document(newProfile.id).setData(from: newProfile, merge: true) { error in
                        if let error = error {
                            errorMessage = "Błąd zapisu profilu: \(error.localizedDescription)"
                        } else {
                            print("Profil użytkownika zapisany w Firestore")
                            // Po udanej rejestracji możesz przejść do głównego widoku aplikacji lub ustawić stan zalogowania
                            dismiss()
                        }
                    }
                } catch {
                    errorMessage = "Błąd podczas przygotowania danych: \(error.localizedDescription)"
                }
            }
        }
    }
}
