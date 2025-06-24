//
//  SettingsView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @AppStorage("preferredColorScheme") private var preferredColorScheme = "system"
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Section
                Section("Account") {
                    if let user = firebaseService.currentUser {
                        HStack {
                            Image(systemName: user.isAnonymous ? "person.circle.fill" : "person.crop.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(user.isAnonymous ? "Anonymous User" : (user.email ?? "User"))
                                    .font(.headline)
                                
                                if user.isModerator {
                                    Text("Moderator")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: { showingSignOutAlert = true }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    Picker("Color Scheme", selection: $preferredColorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Privacy Section
                Section("Privacy & Safety") {
                    NavigationLink(destination: Text("Location Settings")) {
                        Label("Location Settings", systemImage: "location")
                    }
                    
                    NavigationLink(destination: Text("Notification Settings")) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: Text("Help & FAQ")) {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    NavigationLink(destination: Text("About EyesOn")) {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                do {
                    try firebaseService.signOut()
                } catch {
                    print("Sign out error: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onChange(of: preferredColorScheme) { _, newValue in
            updateColorScheme(newValue)
        }
    }
    
    private func updateColorScheme(_ scheme: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        switch scheme {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}
