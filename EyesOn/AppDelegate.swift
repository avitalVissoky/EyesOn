//
//  AppDelegate.swift
//  EyesOn
//
//  Created by Avital on 23/06/2025.
//

import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        return true
    }
}
