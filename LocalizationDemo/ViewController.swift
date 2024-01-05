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
}

