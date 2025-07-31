//
//  EyesOnApp.swift
//  EyesOn
//

import SwiftUI
import Firebase
import BackgroundTasks
import UserNotifications

@main
struct EyesOnApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
        configureNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    PollingNotificationManager.shared.startPolling()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    print("App entered background, polling continues")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await PollingNotificationManager.shared.performPolling()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToReport)) { notification in
                    if let reportId = notification.object as? String {
                        handleReportNavigation(reportId: reportId)
                    }
                }
        }
    }
    
    private func configureNotifications() {
        PollingNotificationManager.shared.setupNotificationActions()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    private func handleReportNavigation(reportId: String) {
        print("Navigate to report: \(reportId)")
    }
}
