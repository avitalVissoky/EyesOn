
//
//  ContentView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var locationManager = LocationManager.shared
  
    var body: some View {
        Group {
            if firebaseService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .onAppear {
            setupApp()
        }
        .preferredColorScheme(.none)
    }
    
    private func setupApp() {
        locationManager.requestLocationPermission()

    }
}

#Preview {
    ContentView()
}
