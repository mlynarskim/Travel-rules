import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
@_exported import GoogleMobileAds
//import FirebaseAuth
//import Firebase
//import GoogleSignIn
//import FirebaseFirestore
//import FirebaseFirestoreSwift
    

enum AuthenticationMethod {
    case email
    case apple
    case google
}

class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: AppUserProfile?
    @Published var isAuthenticated = false
    @Published var authenticationError: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Odwołanie do serwisu, który zarządza zapisem/pobieraniem profilu w Firestore.
    private let userProfileService = UserProfileService.shared
    
    func validatePassword(_ password: String) -> Bool {
        let passwordRegex = #"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    /// Tworzy domyślny profil z minimalną liczbą parametrów
    private func createDefaultUser(name: String, email: String = "no-email@example.com") -> AppUserProfile {
        // Używamy wartości domyślnych zdefiniowanych w AppUserProfile.init(...)
        return AppUserProfile(
            id: "",        // Tymczasowo, nadpiszemy w bazie
            email: email,
            name: name
            // Pozostałe pola (category, status, itp.) są ustawiane domyślnie
        )
    }
    
    // MARK: - Rejestracja (Email/Hasło)
    func registerUser(email: String, password: String, completion: @escaping (Result<AppUserProfile, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "Nie udało się utworzyć użytkownika"
                ])))
                return
            }
            
            // Po udanej rejestracji – tworzymy dokument profilu w Firestore
            let uid = firebaseUser.uid
            let displayName = firebaseUser.displayName ?? "New User"
            let userEmail = firebaseUser.email ?? email
            
            self.userProfileService.createUserProfile(
                uid: uid,
                name: displayName,
                email: userEmail
            ) { [weak self] result in
                switch result {
                case .success(let newProfile):
                    self?.currentUser = newProfile
                    self?.isAuthenticated = true
                    completion(.success(newProfile))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Logowanie (Email/Hasło)
    func loginWithEmail(email: String, password: String, completion: @escaping (Result<AppUserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "Nie udało się pobrać użytkownika"
                ])))
                return
            }
            
            // Pobieramy istniejący profil z Firestore
            let uid = firebaseUser.uid
            self?.userProfileService.fetchUserProfile(uid: uid) { fetchResult in
                switch fetchResult {
                case .success(let profile):
                    self?.currentUser = profile
                    self?.isAuthenticated = true
                    completion(.success(profile))
                    
                case .failure(_):
                    // Jeśli profil nie istnieje, tworzymy nowy profil jako fallback:
                    let displayName = firebaseUser.displayName ?? "User"
                    let userEmail = firebaseUser.email ?? email
                    
                    self?.userProfileService.createUserProfile(
                        uid: uid,
                        name: displayName,
                        email: userEmail
                    ) { createResult in
                        switch createResult {
                        case .success(let newProfile):
                            self?.currentUser = newProfile
                            self?.isAuthenticated = true
                            completion(.success(newProfile))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Logowanie z Apple
    func loginWithApple(userIdentifier: String, fullName: PersonNameComponents?, email: String?, completion: @escaping (Result<AppUserProfile, Error>) -> Void) {
        let uid = userIdentifier
        userProfileService.fetchUserProfile(uid: uid) { [weak self] result in
            switch result {
            case .success(let fetchedProfile):
                self?.currentUser = fetchedProfile
                self?.isAuthenticated = true
                completion(.success(fetchedProfile))
                
            case .failure(_):
                // Tworzymy nowy profil
                let newName = fullName?.givenName ?? "Apple User"
                let newEmail = email ?? "no-email@example.com"
                
                self?.userProfileService.createUserProfile(
                    uid: uid,
                    name: newName,
                    email: newEmail
                ) { createResult in
                    switch createResult {
                    case .success(let newProfile):
                        self?.currentUser = newProfile
                        self?.isAuthenticated = true
                        completion(.success(newProfile))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // MARK: - Logowanie z Google
    func setupGoogleSignIn(completion: @escaping (Result<AppUserProfile, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "GoogleSignInError", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Brak Client ID"
            ])))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure(NSError(domain: "GoogleSignInError", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Nie znaleziono okna aplikacji"
            ])))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let idToken = result?.user.idToken?.tokenString,
                  let accessToken = result?.user.accessToken.tokenString else {
                completion(.failure(NSError(domain: "GoogleSignInError", code: 500, userInfo: [
                    NSLocalizedDescriptionKey: "Nieprawidłowe dane tokena"
                ])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    completion(.failure(NSError(domain: "AuthError", code: 500, userInfo: [
                        NSLocalizedDescriptionKey: "Nie znaleziono użytkownika"
                    ])))
                    return
                }
                
                let uid = firebaseUser.uid
                self?.userProfileService.fetchUserProfile(uid: uid) { fetchResult in
                    switch fetchResult {
                    case .success(let fetchedProfile):
                        self?.currentUser = fetchedProfile
                        self?.isAuthenticated = true
                        completion(.success(fetchedProfile))
                        
                    case .failure(_):
                        // Tworzymy nowy profil, jeśli nie istnieje
                        let newName = firebaseUser.displayName ?? "Google User"
                        let newEmail = firebaseUser.email ?? "no-email@example.com"
                        
                        self?.userProfileService.createUserProfile(
                            uid: uid,
                            name: newName,
                            email: newEmail
                        ) { createResult in
                            switch createResult {
                            case .success(let newProfile):
                                self?.currentUser = newProfile
                                self?.isAuthenticated = true
                                completion(.success(newProfile))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Wylogowanie
    func logout() {
        currentUser = nil
        isAuthenticated = false
        GIDSignIn.sharedInstance.signOut()
        
        do {
            try Auth.auth().signOut()
        } catch {
            print("Błąd wylogowania z Firebase: \(error.localizedDescription)")
        }
    }
}

// MARK: - Apple Sign In Delegate
extension AuthenticationService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In Error: \(error.localizedDescription)")
        authenticationError = error
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Dodatkowe funkcje (np. generowanie tokena)
extension AuthenticationService {
    func generateSecureToken() -> String {
        let uuid = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        let randomComponent = Int.random(in: 0...1000)
        return "\(uuid)-\(timestamp)-\(randomComponent)".sha256()
    }
}

extension String {
    func sha256() -> String {
        let inputData = Data(self.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
