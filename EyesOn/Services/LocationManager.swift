
//
//  LocationManager.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Add this computed property for consistency with ReportViewModel
    var currentLocation: CLLocation? {
        return location
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> CLLocation? {
        return location
    }
    
    func distance(from location1: CLLocation, to location2: CLLocation) -> Double {
        return location1.distance(from: location2)
    }
    
    func reportsWithin5km(reports: [Report], userLocation: CLLocation) -> [Report] {
        return reports.filter { report in
            let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
            return distance(from: userLocation, to: reportLocation) <= 5000 // 5km in meters
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        
        // Update user location and FCM token in Firebase for notifications
        if let currentLocation = locations.last,
           let userId = FirebaseService.shared.currentUser?.uid {
            Task {
                await NotificationManager.shared.updateUserLocationAndToken(
                    location: currentLocation,
                    userId: userId
                )
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}
