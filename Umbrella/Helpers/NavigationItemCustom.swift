//
//  NavigationItemCustom.swift
//  Umbrella
//
//  Created by Lucas Correa on 14/06/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import UIKit
import Localize_Swift

class NavigationItemCustom: NSObject {

    fileprivate var viewController: UIViewController!
    fileprivate var notificationButton: UIButton!
    fileprivate var accountButton: UIButton!
    var accountNavigationController: UINavigationController!
    
    init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
        
        self.addButtons()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLanguage), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
    }
    
    func addButtons() {
        
        if (self.notificationButton != nil) {
            self.notificationButton.removeFromSuperview()
        }
        
        if (self.accountButton != nil) {
            self.accountButton.removeFromSuperview()
        }
        
        // Notification Button
        self.notificationButton = UIButton(type: .custom)
        self.notificationButton.setImage(#imageLiteral(resourceName: "notificationNavigationItem"), for: .normal)
        self.notificationButton.imageView!.tintColor = #colorLiteral(red: 0.3607843137, green: 0.3882352941, blue: 0.4039215686, alpha: 1)
        self.notificationButton.addTarget(self, action: #selector(showNotification), for: .touchUpInside)
        self.viewController.navigationController?.navigationBar.addSubview(self.notificationButton)
        self.notificationButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Account Button
        self.accountButton = UIButton(type: .custom)
        self.accountButton.setImage(#imageLiteral(resourceName: "accountNavigationItem"), for: .normal)
        self.accountButton.addTarget(self, action: #selector(showAccount), for: .touchUpInside)
        self.viewController.navigationController?.navigationBar.addSubview(self.accountButton)
        self.accountButton.translatesAutoresizingMaskIntoConstraints = false
        
        let language: String = UserDefaults.standard.object(forKey: "Language") as? String ?? "en"
        // Arabic(ar) or Persian Farsi(fa)
        if language == "ar" || language == "fa" {
            
            NSLayoutConstraint.activate([
                self.accountButton.widthAnchor.constraint(equalToConstant: 40),
                self.accountButton.heightAnchor.constraint(equalToConstant: 52),
                self.accountButton.leftAnchor.constraint(equalTo: (self.viewController.navigationController?.navigationBar.leftAnchor)!, constant: 5),
                self.accountButton.bottomAnchor.constraint(equalTo: (self.viewController.navigationController?.navigationBar.bottomAnchor)!, constant: 0),
                self.notificationButton.leftAnchor.constraint(equalTo: self.accountButton.leftAnchor, constant: 44),
                self.notificationButton.bottomAnchor.constraint(equalTo: self.accountButton.bottomAnchor, constant: 0),
                self.notificationButton.widthAnchor.constraint(equalToConstant: 40),
                self.notificationButton.heightAnchor.constraint(equalToConstant: 52)
                ])
        } else {
            NSLayoutConstraint.activate([
                self.accountButton.rightAnchor.constraint(equalTo: (self.viewController.navigationController?.navigationBar.rightAnchor)!, constant: -5),
                self.accountButton.bottomAnchor.constraint(equalTo: (self.viewController.navigationController?.navigationBar.bottomAnchor)!, constant: 0),
                self.accountButton.widthAnchor.constraint(equalToConstant: 40),
                self.accountButton.heightAnchor.constraint(equalToConstant: 52),
                
                self.notificationButton.rightAnchor.constraint(equalTo: self.accountButton.rightAnchor, constant: -44),
                self.notificationButton.bottomAnchor.constraint(equalTo: self.accountButton.bottomAnchor, constant: 0),
                self.notificationButton.widthAnchor.constraint(equalToConstant: 40),
                self.notificationButton.heightAnchor.constraint(equalToConstant: 52)
                ])
        }
    }
    
    func showItems(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.notificationButton.alpha = show ? 1.0 : 0.0
            self.accountButton.alpha = show ? 1.0 : 0.0
        }
    }
    
    @objc func updateLanguage() {
        self.addButtons()
    }
    
    @objc func showNotification() {
    }
    
    @objc func showAccount() {
        let storyboard = UIStoryboard(name: "Account", bundle: nil)
        self.accountNavigationController = (storyboard.instantiateViewController(withIdentifier: "AccountNavigationController") as? UINavigationController)!
        self.viewController.present(self.accountNavigationController, animated: true, completion: nil)
//        AccountNavigationController
    }
}