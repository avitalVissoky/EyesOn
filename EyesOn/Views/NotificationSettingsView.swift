//
//  NotificationSettingsView.swift
//  EyesOn
//
//  Created by Avital on 25/06/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = PollingNotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notification Status") {
                    Toggle("Enable Safety Alerts", isOn: Binding(
                        get: { notificationManager.isPollingEnabled },
                        set: { enabled in
                            if enabled {
                                notificationManager.startPolling()
                            } else {
                                notificationManager.stopPolling()
                            }
                        }
                    ))
                    
                    if let lastPoll = notificationManager.lastPollingTime {
                        HStack {
                            Text("Last checked")
                            Spacer()
                            Text(lastPoll, style: .relative)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if notificationManager.isPollingEnabled {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Notifications active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if notificationManager.isPollingEnabled {
                    Section(header: Text("Alert Radius"), footer: Text("You'll receive notifications for reports within this distance from your location.")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Distance")
                                Spacer()
                                Text("\(Int(notificationManager.notificationRadius))m")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { notificationManager.notificationRadius },
                                    set: { notificationManager.updateNotificationRadius($0) }
                                ),
                                in: 500...5000,
                                step: 250
                            ) {
                                Text("Notification Radius")
                            } minimumValueLabel: {
                                Text("500m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Text("5km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Report Categories"), footer: Text("Choose which types of reports you want to be notified about.")) {
                        ForEach(ReportCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.displayName)
                                        .font(.body)
                                    
                                    HStack(spacing: 4) {
                                        Text(category.severity.displayName)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(category.severity.color.opacity(0.2))
                                            .foregroundColor(category.severity.color)
                                            .clipShape(Capsule())
                                        
                                        Text("• \(category.description)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { notificationManager.enabledCategories.contains(category) },
                                    set: { enabled in
                                        var categories = notificationManager.enabledCategories
                                        if enabled {
                                            categories.insert(category)
                                        } else {
                                            categories.remove(category)
                                        }
                                        notificationManager.updateEnabledCategories(categories)
                                    }
                                ))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    Section(header: Text("Severity Filter"), footer: Text("Only receive notifications for reports at or above this severity level.")) {
                        Picker("Minimum Severity", selection: Binding(
                            get: { notificationManager.severityThreshold },
                            set: { notificationManager.updateSeverityThreshold($0) }
                        )) {
                            ForEach(ReportSeverity.allCases, id: \.self) { severity in
                                HStack {
                                    Text(severity.displayName)
                                    Spacer()
                                    Circle()
                                        .fill(severity.color)
                                        .frame(width: 12, height: 12)
                                }
                                .tag(severity)
                            }
                        }
                        .pickerStyle(DefaultPickerStyle())
                    }
                    
                    Section("Quick Actions") {
                        Button("Test Notification") {
                            sendTestNotification()
                        }
                        .foregroundColor(.blue)
                        
                        Button("Force Check Now") {
                            Task {
                                await notificationManager.performPolling()
                            }
                        }
                        .foregroundColor(.blue)
                        
                        Button("Reset Seen Reports") {
                            notificationManager.clearSeenReports()
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from EyesOn. Your notifications are working correctly!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification error: \(error)")
            } else {
                print("Test notification sent successfully")
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}
