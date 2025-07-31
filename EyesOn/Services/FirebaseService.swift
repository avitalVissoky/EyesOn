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
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private func setupAuthListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                Task {
                    await self?.fetchUserData(uid: user.uid)
                }
            } else {
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }

//    private func setupAuthListener() {
////        auth.addStateDidChangeListener { [weak self] _, user in
////            DispatchQueue.main.async {
////                if let user = user {
////                    self?.fetchUserData(uid: user.uid)
////                } else {
////                    self?.currentUser = nil
////                    self?.isAuthenticated = false
////                }
////            }
////        }
//        auth.addStateDidChangeListener { [weak self] _, user in
//            DispatchQueue.main.async {
//                if let user = user {
//                    Task {
//                        await self?.fetchUserData(uid: user.uid)
//                    }
//                } else {
//                    self?.currentUser = nil
//                    self?.isAuthenticated = false
//                }
//            }
//        }
//    }


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
    
    private func fetchUserData(uid: String) async {
        await withCheckedContinuation { continuation in
            database.child("users").child(uid).observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume()
                    return
                }

                let user = User(
                    uid: data["uid"] as? String ?? uid,
                    email: data["email"] as? String,
                    isAnonymous: data["isAnonymous"] as? Bool ?? false,
                    isModerator: data["isModerator"] as? Bool ?? false
                )

                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    continuation.resume()
                }
            }
        }
    }

    
    func submitReport(_ report: Report) async throws -> String {
        let reportData: [String: Any] = [
            "id": report.id,
            "userId": report.userId,
            "category": report.category.rawValue,
            "description": report.description,
            "latitude": report.latitude,
            "longitude": report.longitude,
            "timestamp": report.timestamp.timeIntervalSince1970,
            "status": report.status.rawValue,
            "moderatorId": NSNull()
        ]
        
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
    }
    
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
        
        let categoryString = data["category"] as? String ?? "other"
        let category = ReportCategory(rawValue: categoryString) ?? .other

        return Report(
            id: id,
            userId: userId,
            category: category, 
            description: description,
            latitude: latitude,
            longitude: longitude,
            timestamp: Date(timeIntervalSince1970: timestamp),
            status: status,
            moderatorId: data["moderatorId"] as? String
        )
    }
    
    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }


}
