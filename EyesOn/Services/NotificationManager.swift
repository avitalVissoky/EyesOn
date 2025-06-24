
//
//  NotificationManager.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseMessaging
import UserNotifications
import UIKit
import CoreLocation

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    private let database = Database.database().reference()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("DEBUG: Notification permission granted: \(granted)")
            if let error = error {
                print("DEBUG: Notification permission error: \(error)")
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func sendNearbyReportNotification(reportId: String) async {
        print("DEBUG: Starting to send nearby notifications for report: \(reportId)")
        
        do {
            // 1. Get the approved report details
            guard let report = try await fetchReport(reportId: reportId) else {
                print("DEBUG: Could not fetch report \(reportId)")
                return
            }
            
            print("DEBUG: Fetched report at location: \(report.latitude), \(report.longitude)")
            
            // 2. Get all users with FCM tokens and their locations
            let usersWithTokens = try await fetchUsersWithTokensAndLocations()
            print("DEBUG: Found \(usersWithTokens.count) users with tokens and locations")
            
            // 3. Find users within 5km radius
            let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
            let nearbyUsers = usersWithTokens.filter { user in
                let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
                let distance = reportLocation.distance(from: userLocation)
                let isNearby = distance <= 5000 // 5km in meters
                
                if isNearby {
                    print("DEBUG: User \(user.userId) is \(Int(distance))m away")
                }
                
                return isNearby
            }
            
            print("DEBUG: Found \(nearbyUsers.count) users within 5km")
            
            // 4. Send notifications to nearby users (excluding the reporter)
            let notificationTasks = nearbyUsers.compactMap { user -> Task<Void, Never>? in
                guard user.userId != report.userId else {
                    print("DEBUG: Skipping notification for reporter: \(user.userId)")
                    return nil
                }
                
                return Task {
                    await sendNotificationToUser(
                        user: user,
                        title: "⚠️ Safety Alert",
                        body: "A new safety report has been confirmed in your area. Stay alert!",
                        reportId: reportId
                    )
                }
            }
            
            // Wait for all notifications to be sent
            for task in notificationTasks {
                await task.value
            }
            
            print("DEBUG: Finished sending \(notificationTasks.count) notifications for report: \(reportId)")
            
            // Also send a local notification for testing
            await sendLocalNotificationForTesting(reportId: reportId, nearbyUserCount: nearbyUsers.count)
            
        } catch {
            print("DEBUG: Error sending nearby notifications: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func fetchReport(reportId: String) async throws -> Report? {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports").child(reportId).observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let report = self.parseReport(from: data, withId: reportId)
                continuation.resume(returning: report)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func fetchUsersWithTokensAndLocations() async throws -> [UserWithTokenAndLocation] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("users").observeSingleEvent(of: .value) { snapshot in
                var usersWithTokens: [UserWithTokenAndLocation] = []
                
                for child in snapshot.children {
                    if let userSnapshot = child as? DataSnapshot,
                       let userData = userSnapshot.value as? [String: Any],
                       let fcmToken = userData["fcmToken"] as? String,
                       let latitude = userData["latitude"] as? Double,
                       let longitude = userData["longitude"] as? Double,
                       let locationTimestamp = userData["locationTimestamp"] as? TimeInterval {
                        
                        // Only include users with recent locations (within last 2 hours)
                        let locationDate = Date(timeIntervalSince1970: locationTimestamp)
                        if Date().timeIntervalSince(locationDate) < 7200 { // 2 hours
                            usersWithTokens.append(UserWithTokenAndLocation(
                                userId: userSnapshot.key,
                                fcmToken: fcmToken,
                                latitude: latitude,
                                longitude: longitude,
                                locationTimestamp: locationDate
                            ))
                        }
                    }
                }
                
                continuation.resume(returning: usersWithTokens)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func sendNotificationToUser(user: UserWithTokenAndLocation, title: String, body: String, reportId: String) async {
        print("DEBUG: Sending FCM notification to user: \(user.userId)")
        
        // For now, we'll simulate sending FCM notifications
        // In a real app, you'd call Firebase Cloud Functions or use FCM HTTP API
        print("DEBUG: Would send FCM to token: \(String(user.fcmToken.prefix(20)))...")
        
        // You can implement actual FCM sending here using HTTP requests to FCM API
        // or use Firebase Cloud Functions
    }
    
    private func sendLocalNotificationForTesting(reportId: String, nearbyUserCount: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "📤 Notification Sent"
        content.body = "Safety alert sent to \(nearbyUserCount) nearby users for report \(String(reportId.prefix(8)))"
        content.sound = .default
        content.userInfo = ["reportId": reportId, "type": "notification_sent"]
        
        let request = UNNotificationRequest(
            identifier: "notification-sent-\(reportId)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("DEBUG: Local test notification scheduled")
        } catch {
            print("DEBUG: Error scheduling test notification: \(error)")
        }
    }
    
    private func parseReport(from data: [String: Any], withId id: String) -> Report? {
        guard let userId = data["userId"] as? String,
              let description = data["description"] as? String,
              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              let timestamp = data["timestamp"] as? TimeInterval,
              let statusString = data["status"] as? String,
              let status = Report.ReportStatus(rawValue: statusString) else {
            return nil
        }
        
        // Handle category - provide default if missing for backward compatibility
        let categoryString = data["category"] as? String ?? "other"
        let category = ReportCategory(rawValue: categoryString) ?? .other

        return Report(
            id: id,
            userId: userId,
            category: category, // Add this line
            description: description,
            imageUrl: data["imageUrl"] as? String,
            latitude: latitude,
            longitude: longitude,
            timestamp: Date(timeIntervalSince1970: timestamp),
            status: status,
            moderatorId: data["moderatorId"] as? String
        )
    }
    
    // MARK: - Update User Location and FCM Token
    func updateUserLocationAndToken(location: CLLocation, userId: String) async {
        do {
            // Get current FCM token
            let fcmToken = try await Messaging.messaging().token()
            
            let updates: [String: Any] = [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "locationTimestamp": Date().timeIntervalSince1970,
                "fcmToken": fcmToken
            ]
            
            try await database.child("users").child(userId).updateChildValues(updates)
            print("DEBUG: Updated location and FCM token for user: \(userId)")
            
        } catch {
            print("DEBUG: Error updating user location and token: \(error)")
        }
    }
}

// MARK: - UserWithTokenAndLocation Model
struct UserWithTokenAndLocation {
    let userId: String
    let fcmToken: String
    let latitude: Double
    let longitude: Double
    let locationTimestamp: Date
}

// MARK: - Extensions
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let reportId = userInfo["reportId"] as? String {
            print("DEBUG: User tapped notification for report: \(reportId)")
            // Handle navigation to the report or map
        }
        completionHandler()
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("DEBUG: FCM Token received: \(fcmToken?.prefix(20) ?? "No token")...")
        
        // Update the current user's FCM token in Firebase
        if let token = fcmToken,
           let userId = FirebaseService.shared.currentUser?.uid {
            Task {
                do {
                    try await database.child("users").child(userId).updateChildValues(["fcmToken": token])
                    print("DEBUG: Updated FCM token for user: \(userId)")
                } catch {
                    print("DEBUG: Error updating FCM token: \(error)")
                }
            }
        }
    }
}
