//
//  AppDelegate.swift
//  EyesOn
//

import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Firebase should already be configured in App init, but double-check
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        print("Firebase app configured: \(FirebaseApp.app() != nil)")
        
        return true
    }
}
