
//
//  MainTabView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            ReportListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Reports")
                }
            
            SubmitReportView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Report")
                }
            
            if firebaseService.currentUser?.isModerator == true {
                ModeratorView()
                    .tabItem {
                        Image(systemName: "checkmark.shield")
                        Text("Moderate")
                    }
            }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}
