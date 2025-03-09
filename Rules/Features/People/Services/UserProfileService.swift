import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class UserProfileService {
    static let shared = UserProfileService()
    private let db = Firestore.firestore()
    
    // MARK: - Tworzenie profilu użytkownika
    func createUserProfile(uid: String, name: String, email: String, completion: @escaping (Result<AppUserProfile, Error>) -> Void) {
        // Tworzymy profil z użyciem AppUserProfile – pozostałe pola przyjmują wartości domyślne
        let profile = AppUserProfile(
            id: uid,
            email: email,
            name: name
        )
        
        do {
            try db.collection("users").document(uid).setData(from: profile) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(profile))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Pobieranie profilu użytkownika
    func fetchUserProfile(uid: String, completion: @escaping (Result<AppUserProfile, Error>) -> Void) {
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = document, document.exists else {
                let notFoundError = NSError(
                    domain: "UserProfileService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Profil nie został odnaleziony."]
                )
                completion(.failure(notFoundError))
                return
            }
            do {
                let profile = try document.data(as: AppUserProfile.self)
                completion(.success(profile))
            } catch {
                let decodeError = NSError(
                    domain: "UserProfileService",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Nie udało się zdekodować profilu."]
                )
                completion(.failure(decodeError))
            }
        }
    }
    
    // MARK: - Aktualizacja profilu użytkownika
    func updateUserProfile(uid: String, updatedProfile: AppUserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("users").document(uid).setData(from: updatedProfile, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
