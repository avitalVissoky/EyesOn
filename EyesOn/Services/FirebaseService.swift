//
//  FirebaseService.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import UIKit
import CoreLocation

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let auth = Auth.auth()
    private let database = Database.database().reference()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.fetchUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }

    // MARK: - Authentication
    func signInAnonymously() async throws {
        let result = try await auth.signInAnonymously()
        let user = User(uid: result.user.uid, email: nil, isAnonymous: true)
        try await saveUser(user)
    }
    
    func signInWithEmail(_ email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        await fetchUserData(uid: result.user.uid)
    }
    
    func signUpWithEmail(_ email: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let user = User(uid: result.user.uid, email: email)
        try await saveUser(user)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    private func saveUser(_ user: User) async throws {
        let userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? NSNull(),
            "isAnonymous": user.isAnonymous,
            "isModerator": user.isModerator,
            "createdAt": user.createdAt.timeIntervalSince1970
        ]
        
        try await database.child("users").child(user.uid).setValue(userData)
        
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    private func fetchUserData(uid: String) {
        database.child("users").child(uid).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let data = snapshot.value as? [String: Any] else { return }
            
            let user = User(
                uid: data["uid"] as? String ?? uid,
                email: data["email"] as? String,
                isAnonymous: data["isAnonymous"] as? Bool ?? false,
                isModerator: data["isModerator"] as? Bool ?? false
            )
            
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = true
            }
        }
    }
    
    // MARK: - Reports
    func submitReport(_ report: Report, image: UIImage? = nil) async throws -> String {
        // Handle image storage first if image exists
        var imageUrl: String? = nil
        if let image = image {
            imageUrl = saveImageLocally(image, reportId: report.id)
        }
        
        // Prepare report data
        let reportData: [String: Any] = [
            "id": report.id,
            "userId": report.userId,
            "category": report.category.rawValue, // Add category field
            "description": report.description,
            "imageUrl": imageUrl ?? NSNull(),
            "latitude": report.latitude,
            "longitude": report.longitude,
            "timestamp": report.timestamp.timeIntervalSince1970,
            "status": report.status.rawValue,
            "moderatorId": NSNull()
        ]
        
        // Save to Firebase
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports").child(report.id).setValue(reportData) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: report.id)
                }
            }
        }
    }
    
    func fetchApprovedReports() async throws -> [Report] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports")
                .queryOrdered(byChild: "status")
                .queryEqual(toValue: "approved")
                .observeSingleEvent(of: .value) { snapshot in
                    var reports: [Report] = []
                    
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                           let data = snapshot.value as? [String: Any],
                           let report = self.parseReport(from: data, withId: snapshot.key) {
                            reports.append(report)
                        }
                    }
                    
                    continuation.resume(returning: reports)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func fetchPendingReports() async throws -> [Report] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports")
                .queryOrdered(byChild: "status")
                .queryEqual(toValue: "pending")
                .observeSingleEvent(of: .value) { snapshot in
                    var reports: [Report] = []
                    
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                           let data = snapshot.value as? [String: Any],
                           let report = self.parseReport(from: data, withId: snapshot.key) {
                            reports.append(report)
                        }
                    }
                    
                    continuation.resume(returning: reports)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func updateReportStatus(_ reportId: String, status: Report.ReportStatus, moderatorId: String) async throws {
        let updates: [String: Any] = [
            "status": status.rawValue,
            "moderatorId": moderatorId
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports").child(reportId).updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Send notification to nearby users ONLY if approved
        if status == .approved {
            print("DEBUG: Report approved, sending notifications to nearby users for report: \(reportId)")
            await NotificationManager.shared.sendNearbyReportNotification(reportId: reportId)
        } else {
            print("DEBUG: Report \(reportId) was \(status.rawValue), no notification sent")
        }
    }
    
    // MARK: - Category-specific methods
    func fetchReportsByCategory(_ category: ReportCategory) async throws -> [Report] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports")
                .queryOrdered(byChild: "category")
                .queryEqual(toValue: category.rawValue)
                .observeSingleEvent(of: .value) { snapshot in
                    var reports: [Report] = []
                    
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                           let data = snapshot.value as? [String: Any],
                           let report = self.parseReport(from: data, withId: snapshot.key),
                           report.status == .approved { // Only approved reports
                            reports.append(report)
                        }
                    }
                    
                    continuation.resume(returning: reports)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func fetchRejectedReports() async throws -> [Report] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports")
                .queryOrdered(byChild: "status")
                .queryEqual(toValue: "rejected")
                .observeSingleEvent(of: .value) { snapshot in
                    var reports: [Report] = []
                    
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                           let data = snapshot.value as? [String: Any],
                           let report = self.parseReport(from: data, withId: snapshot.key) {
                            reports.append(report)
                        }
                    }
                    
                    continuation.resume(returning: reports)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func fetchUserReports(userId: String) async throws -> [Report] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("reports")
                .queryOrdered(byChild: "userId")
                .queryEqual(toValue: userId)
                .observeSingleEvent(of: .value) { snapshot in
                    var reports: [Report] = []
                    
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                           let data = snapshot.value as? [String: Any],
                           let report = self.parseReport(from: data, withId: snapshot.key) {
                            reports.append(report)
                        }
                    }
                    
                    continuation.resume(returning: reports)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func fetchAllReportsForUser(userId: String) async throws -> (approved: [Report], pending: [Report], rejected: [Report]) {
        async let approvedReports = fetchApprovedReports()
        async let pendingReports = fetchPendingReports()
        async let rejectedReports = fetchRejectedReports()
        
        let (approved, pending, rejected) = try await (approvedReports, pendingReports, rejectedReports)
        
        return (
            approved: approved.filter { $0.userId == userId },
            pending: pending.filter { $0.userId == userId },
            rejected: rejected.filter { $0.userId == userId }
        )
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
            category: category, // Include category
            description: description,
            imageUrl: data["imageUrl"] as? String,
            latitude: latitude,
            longitude: longitude,
            timestamp: Date(timeIntervalSince1970: timestamp),
            status: status,
            moderatorId: data["moderatorId"] as? String
        )
    }

    // MARK: - Local Image Storage
    private func saveImageLocally(_ image: UIImage, reportId: String) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileName = "\(reportId).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image locally: \(error)")
            return nil
        }
    }

    func loadLocalImage(path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
}
