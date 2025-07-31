//
//  NotificationDelegate.swift
//  EyesOn
//
//  Created by Avital on 25/06/2025.
//
import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "VIEW_REPORT":
            if let reportId = userInfo["reportId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToReport,
                    object: reportId
                )
            }
        case UNNotificationDefaultActionIdentifier:
            // Handle tap on notification body
            if let reportId = userInfo["reportId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToReport,
                    object: reportId
                )
            }
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.alert, .sound, .badge])
        completionHandler([.banner, .sound, .badge])
    }
}

extension Notification.Name {
    static let navigateToReport = Notification.Name("navigateToReport")
}
