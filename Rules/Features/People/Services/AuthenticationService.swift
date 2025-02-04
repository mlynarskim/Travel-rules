//AuthenticationService.swift
import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
@_exported import GoogleMobileAds
import FirebaseAuth
import Firebase
import GoogleSignIn

enum AuthenticationMethod {
    case email
    case apple
    case google
}

class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var authenticationError: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    func validatePassword(_ password: String) -> Bool {
        let passwordRegex = #"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    private func createDefaultUser(name: String, email: String = "no-email@example.com") -> UserProfile {
        UserProfile(
            name: name,
            category: .social,
            status: .available,
            shareLevel: .approximate,
            preferences: UserProfile.UserPreferences()
        )
    }
    
    func registerUser(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Nie udało się utworzyć użytkownika"])))
                return
            }
            
            let user = self.createDefaultUser(name: firebaseUser.displayName ?? "New User", email: firebaseUser.email ?? email)
            self.currentUser = user
            self.isAuthenticated = true
            
            completion(.success(user))
        }
    }
    
    func loginWithEmail(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Nie udało się pobrać użytkownika"])))
                return
            }
            
            let user = self.createDefaultUser(name: firebaseUser.displayName ?? "User", email: firebaseUser.email ?? email)
            self.currentUser = user
            self.isAuthenticated = true
            
            completion(.success(user))
        }
    }
    
    func loginWithApple(userIdentifier: String, fullName: PersonNameComponents?, email: String?, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let user = createDefaultUser(name: fullName?.givenName ?? "Apple User", email: email ?? "")
        self.currentUser = user
        self.isAuthenticated = true
        completion(.success(user))
    }
    
    func setupGoogleSignIn(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "GoogleSignInError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Brak Client ID"])))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure(NSError(domain: "GoogleSignInError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Nie znaleziono okna aplikacji"])))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let idToken = result?.user.idToken?.tokenString,
                  let accessToken = result?.user.accessToken.tokenString else {
                completion(.failure(NSError(domain: "GoogleSignInError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Nieprawidłowe dane tokena"])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    completion(.failure(NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Nie znaleziono użytkownika"])))
                    return
                }
                
                let user = self?.createDefaultUser(name: firebaseUser.displayName ?? "Google User", email: firebaseUser.email ?? "no-email@example.com")
                self?.currentUser = user
                self?.isAuthenticated = true
                
                completion(.success(user!))
            }
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        GIDSignIn.sharedInstance.signOut()
    }
}

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
