//
//  ReportViewModel.swift
//  EyesOn
//
//  Created by Avital on 23/06/2025.
//

import SwiftUI
import CoreLocation

class ReportViewModel: ObservableObject {
    @Published var selectedCategory: ReportCategory?
    @Published var description = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reportSubmittedSuccessfully = false
    
    private let firebaseService = FirebaseService.shared
    private let locationManager = LocationManager.shared
    
    func submitReport() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Get current user
            guard let currentUser = firebaseService.currentUser else {
                throw ReportError.userNotAuthenticated
            }
            
            // Get current location
            guard let location = locationManager.currentLocation else {
                throw ReportError.locationNotAvailable
            }
            
            // Ensure category is selected
            guard let category = selectedCategory else {
                throw ReportError.categoryNotSelected
            }
            
            // Create report object (without image)
            let report = Report(
                id: UUID().uuidString,
                userId: currentUser.uid,
                category: category,
                description: description,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: Date(),
                status: .pending,
                moderatorId: nil
            )
            
            // Submit report to Firebase (without image)
            _ = try await firebaseService.submitReport(report)
            
            await MainActor.run {
                isLoading = false
                reportSubmittedSuccessfully = true
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func resetForm() {
        selectedCategory = nil
        description = ""
        errorMessage = nil
        reportSubmittedSuccessfully = false
    }
}

enum ReportError: LocalizedError {
    case userNotAuthenticated
    case locationNotAvailable
    case categoryNotSelected
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated. Please sign in first."
        case .locationNotAvailable:
            return "Location not available. Please enable location services."
        case .categoryNotSelected:
            return "Please select a report category."
        }
    }
}
