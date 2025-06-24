//
//  ReportsListViewModel.swift
//  EyesOn
//
//  Created by Avital on 23/06/2025.
//

import SwiftUI
import CoreLocation

@MainActor
class ReportsListViewModel: ObservableObject {
    @Published var allReports: [Report] = []
    @Published var myReports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let locationManager = LocationManager.shared
    
    var currentUserId: String? {
        return firebaseService.currentUser?.uid
    }
    
    var myReportsCount: (total: Int, approved: Int, pending: Int, rejected: Int) {
        let approved = myReports.filter { $0.status == .approved }.count
        let pending = myReports.filter { $0.status == .pending }.count
        let rejected = myReports.filter { $0.status == .rejected }.count
        return (total: myReports.count, approved: approved, pending: pending, rejected: rejected)
    }
    
    func loadReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all approved reports for "All Reports" view
            let approvedReports = try await firebaseService.fetchApprovedReports()
            
            // Filter reports within 5km for "All Reports"
            if let userLocation = locationManager.currentLocation {
                allReports = locationManager.reportsWithin5km(
                    reports: approvedReports,
                    userLocation: userLocation
                ).sorted { $0.timestamp > $1.timestamp }
            } else {
                allReports = approvedReports.sorted { $0.timestamp > $1.timestamp }
            }
            
            // Load user's reports (all statuses) for "My Reports" view
            if let userId = currentUserId {
                let userReportsData = try await firebaseService.fetchAllReportsForUser(userId: userId)
                
                // Combine all user reports regardless of status
                myReports = (userReportsData.approved + userReportsData.pending + userReportsData.rejected)
                    .sorted { $0.timestamp > $1.timestamp }
                
                print("DEBUG: User reports - Approved: \(userReportsData.approved.count), Pending: \(userReportsData.pending.count), Rejected: \(userReportsData.rejected.count)")
            } else {
                myReports = []
            }
            
            print("DEBUG: Loaded \(allReports.count) nearby reports and \(myReports.count) user reports")
            
        } catch {
            errorMessage = error.localizedDescription
            print("DEBUG: Error loading reports: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshUserReports() async {
        guard let userId = currentUserId else { return }
        
        do {
            let userReportsData = try await firebaseService.fetchAllReportsForUser(userId: userId)
            myReports = (userReportsData.approved + userReportsData.pending + userReportsData.rejected)
                .sorted { $0.timestamp > $1.timestamp }
            
            print("DEBUG: Refreshed user reports: \(myReports.count) total")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getReportsByStatus(_ status: Report.ReportStatus) -> [Report] {
        return myReports.filter { $0.status == status }
    }
    
    func refreshAllReports() async {
        do {
            let approvedReports = try await firebaseService.fetchApprovedReports()
            
            if let userLocation = locationManager.currentLocation {
                allReports = locationManager.reportsWithin5km(
                    reports: approvedReports,
                    userLocation: userLocation
                ).sorted { $0.timestamp > $1.timestamp }
            } else {
                allReports = approvedReports.sorted { $0.timestamp > $1.timestamp }
            }
            
            print("DEBUG: Refreshed all reports: \(allReports.count) nearby")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
