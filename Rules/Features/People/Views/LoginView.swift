import SwiftUI
import AuthenticationServices
import GoogleSignIn
import Combine

struct LoginView: View {
   @StateObject private var authService = AuthenticationService.shared
   @State private var email = ""
   @State private var password = ""
   @State private var isPasswordVisible = false
   @State private var isLoading = false
   @State private var errorMessage: String?
   
   var body: some View {
       NavigationView {
           VStack(spacing: 20) {
               Text("Zaloguj się")
                   .font(.largeTitle)
                   .fontWeight(.bold)
               
               VStack(spacing: 15) {
                   TextField("Adres email", text: $email)
                       .textFieldStyle(RoundedBorderTextFieldStyle())
                       .keyboardType(.emailAddress)
                       .autocapitalization(.none)
                   
                   HStack {
                       if isPasswordVisible {
                           TextField("Hasło", text: $password)
                       } else {
                           SecureField("Hasło", text: $password)
                       }
                       
                       Button(action: { isPasswordVisible.toggle() }) {
                           Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                               .foregroundColor(.gray)
                       }
                   }
                   .textFieldStyle(RoundedBorderTextFieldStyle())
                   
                   Button(action: loginWithEmail) {
                       Text("Zaloguj się")
                           .frame(maxWidth: .infinity)
                           .padding()
                           .background(Color.blue)
                           .foregroundColor(.white)
                           .cornerRadius(10)
                   }
               }
               
               if let errorMessage = errorMessage {
                   Text(errorMessage)
                       .foregroundColor(.red)
               }
               
               HStack {
                   Rectangle()
                       .frame(height: 1)
                       .foregroundColor(.gray)
                   Text("lub")
                       .foregroundColor(.gray)
                   Rectangle()
                       .frame(height: 1)
                       .foregroundColor(.gray)
               }
               
               VStack(spacing: 15) {
                   SignInWithAppleButton(
                       onRequest: { request in
                           request.requestedScopes = [.fullName, .email]
                       },
                       onCompletion: { result in
                           switch result {
                           case .success(let authorization):
                               handleAppleSignIn(authorization: authorization)
                           case .failure(let error):
                               errorMessage = error.localizedDescription
                           }
                       }
                   )
                   .frame(height: 50)
                   .cornerRadius(10)
                   
                   Button(action: loginWithGoogle) {
                       HStack {
                           Image("google-logo")
                               .resizable()
                               .aspectRatio(contentMode: .fit)
                               .frame(width: 25, height: 25)
                           Text("Kontynuuj przez Google")
                       }
                       .frame(maxWidth: .infinity)
                       .padding()
                       .background(Color.white)
                       .foregroundColor(.black)
                       .overlay(
                           RoundedRectangle(cornerRadius: 10)
                               .stroke(Color.gray, lineWidth: 1)
                       )
                   }
               }
               
               if isLoading {
                   ProgressView()
                       .progressViewStyle(CircularProgressViewStyle())
               }
               
               HStack {
                   Text("Nie masz konta?")
                   NavigationLink(destination: RegistrationView()) {
                       Text("Zarejestruj się")
                           .foregroundColor(.blue)
                   }
               }
           }
           .padding()
           .navigationBarHidden(true)
       }
   }
   
   private func loginWithEmail() {
       isLoading = true
       errorMessage = nil
       
       authService.loginWithEmail(email: email, password: password) { result in
           isLoading = false
           
           switch result {
           case .success(let user):
               print("Zalogowano: \(user.name)")
           case .failure(let error):
               errorMessage = error.localizedDescription
           }
       }
   }
   
   private func loginWithGoogle() {
       guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
             let rootViewController = windowScene.windows.first?.rootViewController else {
           errorMessage = "Błąd konfiguracji widoku"
           return
       }
       
       isLoading = true
       GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
           DispatchQueue.main.async {
               isLoading = false
               if let error = error {
                   errorMessage = error.localizedDescription
                   return
               }
               authService.isAuthenticated = true
           }
       }
   }
   
   private func handleAppleSignIn(authorization: ASAuthorization) {
       guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
           errorMessage = "Błąd autoryzacji Apple"
           return
       }
       
       let userIdentifier = appleIDCredential.user
       let fullName = appleIDCredential.fullName
       let email = appleIDCredential.email
       
       // Wywołaj metodę logowania Apple w serwisie authService
       authService.loginWithApple(userIdentifier: userIdentifier, fullName: fullName, email: email) { result in
           switch result {
           case .success(let user):
               print("Zalogowano za pomocą Apple: \(user.name)")
           case .failure(let error):
               errorMessage = error.localizedDescription
           }
       }
   }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
   static var previews: some View {
       LoginView()
   }
}
#endif
