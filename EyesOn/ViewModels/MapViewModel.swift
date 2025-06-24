//
//  MapViewModel.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation
import MapKit
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.0853, longitude: 34.7818), // Tel Aviv default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @Published var nearbyReports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let locationManager = LocationManager.shared
    
    init() {
        setupLocationUpdates()
        Task {
            await loadReports()
        }
    }
    
    private func setupLocationUpdates() {
        // Request location permission if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestLocationPermission()
        }
        
        // Start location updates if authorized
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startLocationUpdates()
            
            // Update region to user's location if available
            if let userLocation = locationManager.currentLocation {
                updateRegionToUserLocation(userLocation)
            }
        }
    }
    
    private func updateRegionToUserLocation(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func loadReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all approved reports
            let allReports = try await firebaseService.fetchApprovedReports()
            
            // Filter reports within 5km radius if user location is available
            if let userLocation = locationManager.currentLocation {
                nearbyReports = locationManager.reportsWithin5km(
                    reports: allReports,
                    userLocation: userLocation
                )
                
                // Update region to user location
                updateRegionToUserLocation(userLocation)
            } else {
                // If no user location, show all reports
                nearbyReports = allReports
                
                // Center map on reports if available
                if let firstReport = allReports.first {
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: firstReport.latitude,
                            longitude: firstReport.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
            
            print("DEBUG: Loaded \(nearbyReports.count) nearby reports")
            
        } catch {
            errorMessage = "Failed to load reports: \(error.localizedDescription)"
            print("DEBUG: Error loading reports: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshLocation() {
        locationManager.startLocationUpdates()
        
        if let userLocation = locationManager.currentLocation {
            updateRegionToUserLocation(userLocation)
            Task {
                await loadReports()
            }
        }
    }
    
    func focusOnReport(_ report: Report) {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: report.latitude,
                longitude: report.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    }
    
    func filterReportsByCategory(_ category: ReportCategory?) {
        Task {
            isLoading = true
            
            do {
                if let category = category {
                    let categoryReports = try await firebaseService.fetchReportsByCategory(category)
                    
                    if let userLocation = locationManager.currentLocation {
                        nearbyReports = locationManager.reportsWithin5km(
                            reports: categoryReports,
                            userLocation: userLocation
                        )
                    } else {
                        nearbyReports = categoryReports
                    }
                } else {
                    await loadReports()
                    return
                }
                
                print("DEBUG: Filtered to \(nearbyReports.count) reports for category: \(category?.displayName ?? "All")")
                
            } catch {
                errorMessage = "Failed to filter reports: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}
