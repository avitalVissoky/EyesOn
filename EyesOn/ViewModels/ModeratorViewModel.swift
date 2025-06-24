
//
//  ModeratorViewModel.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation

@MainActor
class ModeratorViewModel: ObservableObject {
    @Published var pendingReports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var processingReportIds: Set<String> = []
    
    private let firebaseService = FirebaseService.shared
    
    var isModerator: Bool {
        firebaseService.currentUser?.isModerator ?? false
    }
    
    func loadPendingReports() async {
        guard isModerator else {
            errorMessage = "Unauthorized: Only moderators can view pending reports"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            pendingReports = try await firebaseService.fetchPendingReports()
        } catch {
            errorMessage = "Failed to load reports: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func approveReport(_ report: Report) async {
        print("DEBUG: Approving report \(report.id)")
        await updateReportStatus(report, status: .approved)
    }
    
    func rejectReport(_ report: Report) async {
        print("DEBUG: Rejecting report \(report.id)")
        await updateReportStatus(report, status: .rejected)
    }
    
    private func updateReportStatus(_ report: Report, status: Report.ReportStatus) async {
        guard let moderatorId = firebaseService.currentUser?.uid else {
            errorMessage = "Error: Moderator not authenticated"
            return
        }
        
        // Prevent multiple simultaneous operations on the same report
        guard !processingReportIds.contains(report.id) else {
            print("DEBUG: Report \(report.id) is already being processed")
            return
        }
        
        processingReportIds.insert(report.id)
        
        print("DEBUG: Updating report \(report.id) to status: \(status.rawValue)")
        
        do {
            try await firebaseService.updateReportStatus(report.id, status: status, moderatorId: moderatorId)
            
            // Remove from pending list only after successful update
            pendingReports.removeAll { $0.id == report.id }
            
            print("DEBUG: Successfully updated report \(report.id) to \(status.rawValue)")
            
        } catch {
            errorMessage = "Failed to update report: \(error.localizedDescription)"
            print("DEBUG: Error updating report \(report.id): \(error)")
        }
        
        processingReportIds.remove(report.id)
    }
    
    func isProcessing(_ reportId: String) -> Bool {
        return processingReportIds.contains(reportId)
    }
}
