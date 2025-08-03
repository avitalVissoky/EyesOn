
//
//  MainTabView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//
import SwiftUI

struct MainTabView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var notificationManager = PollingNotificationManager.shared
    
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
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    NotificationStatusIndicator()
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                Spacer()
            }
        )
    }
}

struct NotificationStatusIndicator: View {
    @StateObject private var notificationManager = PollingNotificationManager.shared
    
    var body: some View {
        Button(action: {
            if notificationManager.isPollingEnabled {
                notificationManager.stopPolling()
            } else {
                notificationManager.startPolling()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: notificationManager.isPollingEnabled ? "bell.fill" : "bell.slash")
                    .foregroundColor(notificationManager.isPollingEnabled ? .green : .gray)
                
                if notificationManager.isPollingEnabled {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(notificationManager.lastPollingTime != nil ? 1.0 : 0.5)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}
