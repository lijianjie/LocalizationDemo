//
//  ViewController.swift
//  LocalizationDemo
//
//  Created by 李剑杰 on 1/4/24.
//

import UIKit
import JKSwiftExtension

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "首页"
        
        
        FirebaseLoginType.allCases.forEach({ type in
            let loginButton = UIButton().title(type.title()).textColor(.blue).tag(type.rawValue)
            loginButton.layer.borderWidth(1).borderColor(.blue).corner(25)
            loginButton.addTo(view)
                .makeConstraints { make in
                    make.left.right.equalToSuperview().inset(40)
                    make.bottom.equalToSuperview().inset(40 + 70 * type.rawValue)
                    make.height.equalTo(50)
                }
            loginButton.addTarget(self, action: #selector(loginButtonClicked(_:)), for: .touchUpInside)
        })
    }
}

extension ViewController {
    // 登录
    @objc func loginButtonClicked(_ sender: UIButton) {
        guard let type = FirebaseLoginType(rawValue: sender.tag) else { return }
        
        FirebaseAuth.shared.signIn(type: type, withPresenting: self)
    }
    
//    private func facebookLogin() {
//        if AccessToken.isCurrentAccessTokenActive { return }
//        
//        let loginManager = LoginManager()
//        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { result, error in
//            if let error {
//                print("Erorr: \(error)")
//            } else if let result = result, result.isCancelled {
//                print("Cancelled")
//            } else {
//                print("Logged In")
//            }
//        }
//    }
    
//    private func googleLogin(_ clientID: String) {
//        // Create Google Sign In configuration object.
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//        
//        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
//            if let error {
//                print("Erorr: \(error)")
//                return
//            }
//            
//            guard
//                let user = signInResult?.user,
//                let idToken = user.idToken?.tokenString
//            else {
//                print("Cancelled")
//                return
//            }
//            
//            let emailAddress = user.profile?.email
//            let fullName = user.profile?.name
//            let givenName = user.profile?.givenName
//            let familyName = user.profile?.familyName
//            let profilePicUrl = user.profile?.imageURL(withDimension: 320)
//            
//            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
//            Auth.auth().signIn(with: credential) { result, error in
//
//              // At this point, our user is signed in
//            }
//                
//        }
//    }
}

