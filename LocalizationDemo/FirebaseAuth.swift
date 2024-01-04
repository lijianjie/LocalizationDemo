//
//  FirebaseAuth.swift
//  LocalizationDemo
//
//  Created by 李剑杰 on 1/4/24.
//

import UIKit
import CryptoKit
import AuthenticationServices
import GoogleSignIn
import FBSDKLoginKit

enum FirebaseLoginType: Int,CaseIterable {
    case google
    case facebook
    case apple
    
    func title() -> String {
        switch self {
        case .google:
            return "Login with Google"
        case .facebook:
            return "Login with Facebook"
        case .apple:
            return "Login with Apple"
        }
    }
}

class FirebaseAuth: NSObject {
    static let shared = FirebaseAuth()
    
    // Nonce 用于防止重放攻击
    private var currentNonce: String?
    private var presentingViewControler: UIViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("[DEBUG]::openURL: \(url)")
        
        if GIDSignIn.sharedInstance.handle(url) { return true }
        
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        
        print("[DEBUG]::scene: \(url)")
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func signIn(type: FirebaseLoginType, withPresenting vc: UIViewController) {
        presentingViewControler = vc
        
        switch type {
        case .google:
            googleSignIn(withPresenting: vc)
        case .facebook:
            facebookSignIn(withPresenting: vc)
        case .apple:
            appleSignIn(withPresenting: vc)
        }
        
    }
    
    func signOut(type: FirebaseLoginType) {
        switch type {
        case .google:
            GIDSignIn.sharedInstance.signOut()
        case .facebook:
            LoginManager().logOut()
        case .apple:
            break
            
        }
    }
}

// Google
extension FirebaseAuth {
    private func googleSignIn(withPresenting vc: UIViewController) {
        GIDSignIn.sharedInstance.signIn(withPresenting: vc) { signInResult, error in
            guard error == nil else { return }
            guard let signInResult = signInResult else { return }
            
            //            let user = signInResult.user
            //            let emailAddress = user.profile?.email
            //            let fullName = user.profile?.name
            //            let givenName = user.profile?.givenName
            //            let familyName = user.profile?.familyName
            //            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            print("[DEBUG]:: signIn with Google")
        }
    }
}

// Facebook
extension FirebaseAuth {
    private func facebookSignIn(withPresenting vc: UIViewController) {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["email", "public_profile"], from: vc) { result, error in
            guard error == nil else { return } // Error
            guard
                let result = result,
                !result.isCancelled,
                let token = result.token
            else { return } // Cancelled
            
            print(token)
            print("[DEBUG]:: signIn with Facebook")
        }
    }
}

fileprivate func randomNonceString() -> String {
    var keyData = Data(count: 32)
    let result = keyData.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
    }
    if result == errSecSuccess {
        return keyData.base64EncodedString()
    } else {
        return keyData.base64EncodedString()
    }
}

@available(iOS 13, *)
fileprivate func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

// Apple
extension FirebaseAuth: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private func appleSignIn(withPresenting vc: UIViewController) {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentingViewControler?.view.window ?? UIWindow()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    /** - Tag: did_complete_authorization
     * 1. 与许多其他身份提供商不同，Apple 不提供照片网址。
     * 2. 如果用户选择不与应用分享其真实电子邮件，Apple 会为该用户预配唯一的电子邮件地址来与应用共享。此电子邮件的格式为 xyz@privaterelay.appleid.com。如果您配置了私人电子邮件中继服务，则 Apple 会将发送到匿名地址的电子邮件转发到用户的真实电子邮件地址。
     * 3. Apple 只会在用户首次登录时与应用共享用户信息（例如显示名
     **/
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let nonce = currentNonce else {
          fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let userName = fullName?.givenName ?? fullName?.familyName ?? ""
            let email = appleIDCredential.email
            
            // For the purpose of this demo app, store the `userIdentifier` in the keychain.
            self.saveUserInKeychain(userIdentifier)
            
            print("[DEBUG]:: signIn with Apple")
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                self.showPasswordCredentialAlert(username: userName, email: email)
            }
            
        case let passwordCredential as ASPasswordCredential:
            
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            print("[DEBUG]:: signIn with Apple")
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                self.showPasswordCredentialAlert(username: username, password: password)
            }
            
        default:
            break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
       // Handle error.
       print("Sign in with Apple errored: \(error)")
     }
    
    private func saveUserInKeychain(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.cocoa.localizationDemo", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
    
    private func showPasswordCredentialAlert(username: String, password: String? = nil, email: String? = nil) {
        guard let presentingVC = presentingViewControler else { return }
        
        var content = "Username: \(username)"
        if let password {
            content.append("\n Password: \(password)")
        }
        if let email {
            content.append("\n Email: \(email)")
        }
        let message = "The app has received your selected credential from the keychain. \n\n \(content)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        presentingVC.present(alertController, animated: true, completion: nil)
    }
}
