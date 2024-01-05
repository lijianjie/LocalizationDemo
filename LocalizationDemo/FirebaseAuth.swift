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

fileprivate func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
        fatalError(
            "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
    }
    
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
    }
    
    return String(nonce)
}

@available(iOS 13, *)
private func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    String(format: "%02x", $0)
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
     * 3. Apple 只会在用户首次登录时与应用共享用户信息
     **/
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // 苹果用户唯一标识符，该值在同一个开发者账号下的所有 App 下是一样的，开发者可以用该唯一标识符与自己后台系统的账号体系绑定起来。
            let userIdentifier = credential.user
            // 苹果用户信息 如果授权过，可能无法再次获取该信息
            let fullName = credential.fullName
            let userName = fullName?.givenName ?? fullName?.familyName ?? ""
            let email = credential.email ?? ""
//            let realUserStatus = credential.realUserStatus
            print("[DEBUG]:: userName = \(userName); email = \(email);")
            
            // Securely store the userIdentifier locally
            self.saveUserIdentifier(userIdentifier)
            
            // 服务器验证需要使用的参数
//            let state = credential.state ?? ""
//            let identityToken = credential.identityToken
//            let authorizationCode = credential.authorizationCode
//            // Create a session with your server and verify the information
//            self.createSession(identityToken: identityToken, authorizationCode: authorizationCode)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let authError = error as? ASAuthorizationError else {
            print("[DEBUG]::Apple: Error \(error.localizedDescription)")
            return
        }
        switch (authError.code) {
        case .canceled:
            print("[DEBUG]::Apple:用户取消了授权请求")
        case .failed:
            print("[DEBUG]::Apple:授权请求失败")
        case .invalidResponse:
            print("[DEBUG]::Apple:授权请求响应无效")
        case .notHandled:
            print("[DEBUG]::Apple:未能处理授权请求")
        default:
            print("[DEBUG]::Apple: Error \(error.localizedDescription)")
        }
     }
    
    private func saveUserIdentifier(_ userIdentifier: String) {
        do {
            try KeychainItem(service: "com.cocoa.localizationDemo", account: "userIdentifier").saveItem(userIdentifier)
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }
}
