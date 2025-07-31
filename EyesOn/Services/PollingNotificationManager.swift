
//  PollingNotificationManager.swift
//  EyesOn
//
//  Created by Avital on 25/06/2025.
//

import Foundation
import UserNotifications
import CoreLocation
import BackgroundTasks

class PollingNotificationManager: ObservableObject {
    static let shared = PollingNotificationManager()
    
    @Published var isPollingEnabled = false
    @Published var lastPollingTime: Date?
    
    private var pollingTimer: Timer?
    private let firebaseService = FirebaseService.shared
    private let locationManager = LocationManager.shared
    private var seenReportIds = Set<String>()
    
    // Polling configuration
    private let pollingInterval: TimeInterval = 30 // 30 seconds
    private let backgroundTaskIdentifier = "com.eyeson.background-polling"
    
    @Published var notificationRadius: Double = 2000 // 2km in meters
    @Published var enabledCategories: Set<ReportCategory> = Set(ReportCategory.allCases)
    @Published var severityThreshold: ReportSeverity = .medium
    
    private init() {
        requestNotificationPermission()
        loadSeenReports()
        loadSettings()
        registerBackgroundTask()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundPolling(task: task as! BGAppRefreshTask)
        }
    }
    
    
    func startPolling() {
        guard !isPollingEnabled else { return }
        
        isPollingEnabled = true
        setupPollingTimer()
        scheduleBackgroundPolling()
        
        // Initial poll
        Task {
            await executePolling()
        }
        
        print("Started notification polling with \(pollingInterval)s interval")
    }
    
    func stopPolling() {
        isPollingEnabled = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        cancelBackgroundPolling()
        
        print("Stopped notification polling")
    }
    
    private func setupPollingTimer() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { _ in
            Task {
                await self.executePolling()
            }
        }
    }
    
    
    private func scheduleBackgroundPolling() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: pollingInterval)
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func cancelBackgroundPolling() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
    }
    
    private func handleBackgroundPolling(task: BGAppRefreshTask) {
        scheduleBackgroundPolling()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await executePolling()
            task.setTaskCompleted(success: true)
        }
    }
    
    @MainActor
    private func executePolling() async {
        guard isPollingEnabled else { return }
        
        do {
            guard let userLocation = locationManager.currentLocation else {
                print("No user location available for polling")
                return
            }
            
            let allReports = try await firebaseService.fetchApprovedReports()
            
            let nearbyReports = filterReportsWithinRadius(
                reports: allReports,
                userLocation: userLocation,
                radius: notificationRadius
            )
            
            let newReports = findNewReports(in: nearbyReports)
            
            let relevantReports = filterReportsByPreferences(newReports)
            
            for report in relevantReports {
                await sendNotification(for: report, userLocation: userLocation)
            }
            
            updateSeenReports(with: nearbyReports)
            lastPollingTime = Date()
            
            print("Polling completed: \(newReports.count) new reports, \(relevantReports.count) notifications sent")
            
        } catch {
            print("Polling error: \(error.localizedDescription)")
        }
    }
    
    func performPolling() async {
        await executePolling()
    }
    
    private func filterReportsWithinRadius(reports: [Report], userLocation: CLLocation, radius: Double) -> [Report] {
        return reports.filter { report in
            let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
            return userLocation.distance(from: reportLocation) <= radius
        }
    }
    
    private func findNewReports(in reports: [Report]) -> [Report] {
        return reports.filter { report in
            !seenReportIds.contains(report.id)
        }
    }
    
    private func filterReportsByPreferences(_ reports: [Report]) -> [Report] {
        return reports.filter { report in
            guard enabledCategories.contains(report.category) else { return false }
            

            guard report.category.severity.priority >= severityThreshold.priority else { return false }
            
            guard report.userId != firebaseService.currentUser?.uid else { return false }
            
            return true
        }
    }
    
    
    private func sendNotification(for report: Report, userLocation: CLLocation) async {
        let content = UNMutableNotificationContent()
        content.title = "New Safety Report Nearby"
        content.body = createNotificationBody(for: report, userLocation: userLocation)
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        content.userInfo = [
            "reportId": report.id,
            "reportLatitude": report.latitude,
            "reportLongitude": report.longitude,
            "reportCategory": report.category.rawValue
        ]
        
        content.categoryIdentifier = "REPORT_NOTIFICATION"
        
        let request = UNNotificationRequest(
            identifier: "report_\(report.id)",
            content: content,
            trigger: nil 
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Sent notification for report: \(report.id)")
        } catch {
            print("Failed to send notification: \(error.localizedDescription)")
        }
    }
    
    private func createNotificationBody(for report: Report, userLocation: CLLocation) -> String {
        let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
        let distance = userLocation.distance(from: reportLocation)
        let distanceString = distance < 1000 ? "\(Int(distance))m" : "\(String(format: "%.1f", distance/1000))km"
        
        return "\(report.category.displayName) reported \(distanceString) away: \(report.description.prefix(50))..."
    }
    
    private func updateSeenReports(with reports: [Report]) {
        for report in reports {
            seenReportIds.insert(report.id)
        }
        
        // Keep only recent report IDs to prevent memory bloat
        if seenReportIds.count > 1000 {
            let reportIds = Array(seenReportIds)
            seenReportIds = Set(reportIds.suffix(500))
        }
        
        saveSeenReports()
    }
    
    private func saveSeenReports() {
        let array = Array(seenReportIds)
        UserDefaults.standard.set(array, forKey: "seenReportIds")
    }
    
    private func loadSeenReports() {
        if let array = UserDefaults.standard.array(forKey: "seenReportIds") as? [String] {
            seenReportIds = Set(array)
        }
    }
    
    
    func updateNotificationRadius(_ radius: Double) {
        notificationRadius = radius
        UserDefaults.standard.set(radius, forKey: "notificationRadius")
    }
    
    func updateEnabledCategories(_ categories: Set<ReportCategory>) {
        enabledCategories = categories
        let categoryStrings = categories.map { $0.rawValue }
        UserDefaults.standard.set(categoryStrings, forKey: "enabledCategories")
    }
    
    func updateSeverityThreshold(_ severity: ReportSeverity) {
        severityThreshold = severity
        UserDefaults.standard.set(severity.rawValue, forKey: "severityThreshold")
    }
    
    private func loadSettings() {
        let savedRadius = UserDefaults.standard.double(forKey: "notificationRadius")
        if savedRadius > 0 {
            notificationRadius = savedRadius
        }
        

        if let categoryStrings = UserDefaults.standard.array(forKey: "enabledCategories") as? [String] {
            enabledCategories = Set(categoryStrings.compactMap { ReportCategory(rawValue: $0) })
        }
        
        if let severityString = UserDefaults.standard.string(forKey: "severityThreshold"),
           let severity = ReportSeverity(rawValue: severityString) {
            severityThreshold = severity
        }
    }
    

    
    func clearSeenReports() {
        seenReportIds.removeAll()
        UserDefaults.standard.removeObject(forKey: "seenReportIds")
    }
    
    var seenReportsCount: Int {
        return seenReportIds.count
    }
    
    func setupNotificationActions() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_REPORT",
            title: "View Report",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "REPORT_NOTIFICATION",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
