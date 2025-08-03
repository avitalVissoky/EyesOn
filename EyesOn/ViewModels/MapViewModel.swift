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
        center: CLLocationCoordinate2D(latitude: 32.0853, longitude: 34.7818),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var nearbyReports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let locationManager = LocationManager.shared
    
    // Add zoom constraints
    private let minZoomLevel: Double = 0.001   // Maximum zoom in
    private let maxZoomLevel: Double = 10.0    // Maximum zoom out
    
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
        
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startLocationUpdates()
            

            if let userLocation = locationManager.currentLocation {
                updateRegionToUserLocation(userLocation)
            }
        }
    }
    
    private func updateRegionToUserLocation(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }
    
    private func constrainRegion(_ newRegion: MKCoordinateRegion) -> MKCoordinateRegion {
        var constrainedRegion = newRegion
        
        if constrainedRegion.span.latitudeDelta < minZoomLevel {
            constrainedRegion.span.latitudeDelta = minZoomLevel
        }
        if constrainedRegion.span.longitudeDelta < minZoomLevel {
            constrainedRegion.span.longitudeDelta = minZoomLevel
        }
        
        if constrainedRegion.span.latitudeDelta > maxZoomLevel {
            constrainedRegion.span.latitudeDelta = maxZoomLevel
        }
        if constrainedRegion.span.longitudeDelta > maxZoomLevel {
            constrainedRegion.span.longitudeDelta = maxZoomLevel
        }
        
        if constrainedRegion.center.latitude > 85 {
            constrainedRegion.center.latitude = 85
        }
        if constrainedRegion.center.latitude < -85 {
            constrainedRegion.center.latitude = -85
        }
        
        if constrainedRegion.center.longitude > 180 {
            constrainedRegion.center.longitude = 180
        }
        if constrainedRegion.center.longitude < -180 {
            constrainedRegion.center.longitude = -180
        }
        
        return constrainedRegion
    }
    
    func updateRegion(_ newRegion: MKCoordinateRegion) {
        region = constrainRegion(newRegion)
    }
    
    func loadReports() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allReports = try await firebaseService.fetchApprovedReports()
            
            if let userLocation = locationManager.currentLocation {
                nearbyReports = locationManager.reportsWithin5km(
                    reports: allReports,
                    userLocation: userLocation
                )
                
                let userRegion = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                region = constrainRegion(userRegion)
            } else {
                nearbyReports = allReports
                
                if let firstReport = allReports.first {
                    let reportRegion = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: firstReport.latitude,
                            longitude: firstReport.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    region = constrainRegion(reportRegion)
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
        let focusRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: report.latitude,
                longitude: report.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        region = constrainRegion(focusRegion)
    }
    
    func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 0.5,
            longitudeDelta: region.span.longitudeDelta * 0.5
        )
        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
        region = constrainRegion(newRegion)
    }
    
    func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 2.0,
            longitudeDelta: region.span.longitudeDelta * 2.0
        )
        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
        region = constrainRegion(newRegion)
    }
    
    func resetToUserLocation() {
        if let userLocation = locationManager.currentLocation {
            updateRegionToUserLocation(userLocation)
        }
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
