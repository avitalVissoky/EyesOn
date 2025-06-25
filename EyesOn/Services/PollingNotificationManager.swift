////
////  PollingNotificationManager.swift
////  EyesOn
////
////  Created by Avital on 25/06/2025.
////
//
//import Foundation
//import UserNotifications
//import CoreLocation
//import BackgroundTasks
//
//class PollingNotificationManager: ObservableObject {
//    static let shared = PollingNotificationManager()
//    
//    @Published var isPollingEnabled = false
//    @Published var lastPollingTime: Date?
//    
//    private var pollingTimer: Timer?
//    private let firebaseService = FirebaseService.shared
//    private let locationManager = LocationManager.shared
//    private var lastKnownReportCount = 0
//    private var seenReportIds = Set<String>()
//    
//    // Polling configuration
//    private let pollingInterval: TimeInterval = 30 // 30 seconds
//    private let backgroundTaskIdentifier = "com.eyeson.background-polling"
//    
//    // User preferences
//    @Published var notificationRadius: Double = 2000 // 2km in meters
//    @Published var enabledCategories: Set<ReportCategory> = Set(ReportCategory.allCases)
//    @Published var severityThreshold: ReportSeverity = .medium
//    
//    private init() {
//        requestNotificationPermission()
//        loadSeenReports()
//        registerBackgroundTask()
//    }
//    
//    // MARK: - Permission and Setup
//    
//    private func requestNotificationPermission() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            DispatchQueue.main.async {
//                if granted {
//                    print("Notification permission granted")
//                } else {
//                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
//                }
//            }
//        }
//    }
//    
//    private func registerBackgroundTask() {
//        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
//            self.handleBackgroundPolling(task: task as! BGAppRefreshTask)
//        }
//    }
//    
//    // MARK: - Polling Control
//    
//    func startPolling() {
//        guard !isPollingEnabled else { return }
//        
//        isPollingEnabled = true
//        setupPollingTimer()
//        scheduleBackgroundPolling()
//        
//        // Initial poll
//        Task {
//            await performPolling()
//        }
//        
//        print("Started notification polling with \(pollingInterval)s interval")
//    }
//    
//    func stopPolling() {
//        isPollingEnabled = false
//        pollingTimer?.invalidate()
//        pollingTimer = nil
//        cancelBackgroundPolling()
//        
//        print("Stopped notification polling")
//    }
//    
//    private func setupPollingTimer() {
//        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { _ in
//            Task {
//                await self.performPolling()
//            }
//        }
//    }
//    
//    // MARK: - Background Polling
//    
//    private func scheduleBackgroundPolling() {
//        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
//        request.earliestBeginDate = Date(timeIntervalSinceNow: pollingInterval)
//        
//        try? BGTaskScheduler.shared.submit(request)
//    }
//    
//    private func cancelBackgroundPolling() {
//        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
//    }
//    
//    private func handleBackgroundPolling(task: BGAppRefreshTask) {
//        // Schedule next background polling
//        scheduleBackgroundPolling()
//        
//        task.expirationHandler = {
//            task.setTaskCompleted(success: false)
//        }
//        
//        Task {
//            await performPolling()
//            task.setTaskCompleted(success: true)
//        }
//    }
//    
//    // MARK: - Core Polling Logic
//    
//    @MainActor
//    private func performPolling() async {
//        guard isPollingEnabled else { return }
//        
//        do {
//            // Get current location
//            guard let userLocation = locationManager.currentLocation else {
//                print("No user location available for polling")
//                return
//            }
//            
//            // Fetch latest reports
//            let allReports = try await firebaseService.fetchApprovedReports()
//            
//            // Filter reports within notification radius
//            let nearbyReports = filterReportsWithinRadius(
//                reports: allReports,
//                userLocation: userLocation,
//                radius: notificationRadius
//            )
//            
//            // Find new reports since last poll
//            let newReports = findNewReports(in: nearbyReports)
//            
//            // Filter by user preferences
//            let relevantReports = filterReportsByPreferences(newReports)
//            
//            // Send notifications for relevant reports
//            for report in relevantReports {
//                await sendNotification(for: report, userLocation: userLocation)
//            }
//            
//            // Update tracking
//            updateSeenReports(with: nearbyReports)
//            lastPollingTime = Date()
//            
//            print("Polling completed: \(newReports.count) new reports, \(relevantReports.count) notifications sent")
//            
//        } catch {
//            print("Polling error: \(error.localizedDescription)")
//        }
//    }
//    
//    // MARK: - Filtering Logic
//    
//    private func filterReportsWithinRadius(reports: [Report], userLocation: CLLocation, radius: Double) -> [Report] {
//        return reports.filter { report in
//            let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
//            return userLocation.distance(from: reportLocation) <= radius
//        }
//    }
//    
//    private func findNewReports(in reports: [Report]) -> [Report] {
//        return reports.filter { report in
//            !seenReportIds.contains(report.id)
//        }
//    }
//    
//    private func filterReportsByPreferences(_ reports: [Report]) -> [Report] {
//        return reports.filter { report in
//            // Check if category is enabled
//            guard enabledCategories.contains(report.category) else { return false }
//            
//            // Check severity threshold
//            guard report.category.severity.rawValue >= severityThreshold.rawValue else { return false }
//            
//            // Don't notify about user's own reports
//            guard report.userId != firebaseService.currentUser?.uid else { return false }
//            
//            return true
//        }
//    }
//    
//    // MARK: - Notification Sending
//    
//    private func sendNotification(for report: Report, userLocation: CLLocation) async {
//        let content = UNMutableNotificationContent()
//        content.title = "New Safety Report Nearby"
//        content.body = createNotificationBody(for: report, userLocation: userLocation)
//        content.sound = UNNotificationSound.default
//        content.badge = 1
//        
//        // Add user info for handling taps
//        content.userInfo = [
//            "reportId": report.id,
//            "reportLatitude": report.latitude,
//            "reportLongitude": report.longitude,
//            "reportCategory": report.category.rawValue
//        ]
//        
//        // Set category for notification actions
//        content.categoryIdentifier = "REPORT_NOTIFICATION"
//        
//        // Create request
//        let request = UNNotificationRequest(
//            identifier: "report_\(report.id)",
//            content: content,
//            trigger: nil // Send immediately
//        )
//        
//        do {
//            try await UNUserNotificationCenter.current().add(request)
//            print("Sent notification for report: \(report.id)")
//        } catch {
//            print("Failed to send notification: \(error.localizedDescription)")
//        }
//    }
//    
//    private func createNotificationBody(for report: Report, userLocation: CLLocation) -> String {
//        let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
//        let distance = userLocation.distance(from: reportLocation)
//        let distanceString = distance < 1000 ? "\(Int(distance))m" : "\(String(format: "%.1f", distance/1000))km"
//        
//        return "\(report.category.displayName) reported \(distanceString) away: \(report.description.prefix(50))..."
//    }
//    
//    // MARK: - Data Persistence
//    
//    private func updateSeenReports(with reports: [Report]) {
//        for report in reports {
//            seenReportIds.insert(report.id)
//        }
//        
//        // Keep only recent report IDs to prevent memory bloat
//        if seenReportIds.count > 1000 {
//            let reportIds = Array(seenReportIds)
//            seenReportIds = Set(reportIds.suffix(500))
//        }
//        
//        saveSeenReports()
//    }
//    
//    private func saveSeenReports() {
//        let array = Array(seenReportIds)
//        UserDefaults.standard.set(array, forKey: "seenReportIds")
//    }
//    
//    private func loadSeenReports() {
//        if let array = UserDefaults.standard.array(forKey: "seenReportIds") as? [String] {
//            seenReportIds = Set(array)
//        }
//    }
//    
//    // MARK: - Settings Management
//    
//    func updateNotificationRadius(_ radius: Double) {
//        notificationRadius = radius
//        UserDefaults.standard.set(radius, forKey: "notificationRadius")
//    }
//    
//    func updateEnabledCategories(_ categories: Set<ReportCategory>) {
//        enabledCategories = categories
//        let categoryStrings = categories.map { $0.rawValue }
//        UserDefaults.standard.set(categoryStrings, forKey: "enabledCategories")
//    }
//    
//    func updateSeverityThreshold(_ severity: ReportSeverity) {
//        severityThreshold = severity
//        UserDefaults.standard.set(severity.rawValue, forKey: "severityThreshold")
//    }
//    
//    private func loadSettings() {
//        notificationRadius = UserDefaults.standard.double(forKey: "notificationRadius")
//        if notificationRadius == 0 { notificationRadius = 2000 } // Default
//        
//        if let categoryStrings = UserDefaults.standard.array(forKey: "enabledCategories") as? [String] {
//            enabledCategories = Set(categoryStrings.compactMap { ReportCategory(rawValue: $0) })
//        }
//        
//        if let severityString = UserDefaults.standard.string(forKey: "severityThreshold"),
//           let severity = ReportSeverity(rawValue: severityString) {
//            severityThreshold = severity
//        }
//    }
//}
//
//// MARK: - Notification Actions Setup
//
//extension PollingNotificationManager {
//    func setupNotificationActions() {
//        let viewAction = UNNotificationAction(
//            identifier: "VIEW_REPORT",
//            title: "View Report",
//            options: [.foreground]
//        )
//        
//        let dismissAction = UNNotificationAction(
//            identifier: "DISMISS",
//            title: "Dismiss",
//            options: []
//        )
//        
//        let category = UNNotificationCategory(
//            identifier: "REPORT_NOTIFICATION",
//            actions: [viewAction, dismissAction],
//            intentIdentifiers: [],
//            options: []
//        )
//        
//        UNUserNotificationCenter.current().setNotificationCategories([category])
//    }
//}
//
//// MARK: - Settings View
//
//struct NotificationSettingsView: View {
//    @StateObject private var notificationManager = PollingNotificationManager.shared
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                Section("Notification Status") {
//                    Toggle("Enable Notifications", isOn: Binding(
//                        get: { notificationManager.isPollingEnabled },
//                        set: { enabled in
//                            if enabled {
//                                notificationManager.startPolling()
//                            } else {
//                                notificationManager.stopPolling()
//                            }
//                        }
//                    ))
//                    
//                    if let lastPoll = notificationManager.lastPollingTime {
//                        Text("Last checked: \(lastPoll, style: .relative) ago")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//                Section("Notification Radius") {
//                    VStack(alignment: .leading) {
//                        Text("Notify within \(Int(notificationManager.notificationRadius))m")
//                        Slider(
//                            value: Binding(
//                                get: { notificationManager.notificationRadius },
//                                set: { notificationManager.updateNotificationRadius($0) }
//                            ),
//                            in: 500...5000,
//                            step: 500
//                        )
//                    }
//                }
//                
//                Section("Report Categories") {
//                    ForEach(ReportCategory.allCases, id: \.self) { category in
//                        Toggle(category.displayName, isOn: Binding(
//                            get: { notificationManager.enabledCategories.contains(category) },
//                            set: { enabled in
//                                var categories = notificationManager.enabledCategories
//                                if enabled {
//                                    categories.insert(category)
//                                } else {
//                                    categories.remove(category)
//                                }
//                                notificationManager.updateEnabledCategories(categories)
//                            }
//                        ))
//                    }
//                }
//                
//                Section("Severity Threshold") {
//                    Picker("Minimum Severity", selection: Binding(
//                        get: { notificationManager.severityThreshold },
//                        set: { notificationManager.updateSeverityThreshold($0) }
//                    )) {
//                        ForEach(ReportSeverity.allCases, id: \.self) { severity in
//                            Text(severity.displayName).tag(severity)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Notification Settings")
//        }
//    }
//}
//
//// MARK: - App Integration
//
//extension App {
//    func configureNotifications() {
//        // Set up notification actions
//        PollingNotificationManager.shared.setupNotificationActions()
//        
//        // Handle notification responses
//        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
//    }
//}
//
//class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
//    static let shared = NotificationDelegate()
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        
//        let userInfo = response.notification.request.content.userInfo
//        
//        switch response.actionIdentifier {
//        case "VIEW_REPORT":
//            if let reportId = userInfo["reportId"] as? String {
//                // Navigate to report detail
//                NotificationCenter.default.post(
//                    name: .navigateToReport,
//                    object: reportId
//                )
//            }
//        case UNNotificationDefaultActionIdentifier:
//            // Handle tap on notification body
//            if let reportId = userInfo["reportId"] as? String {
//                NotificationCenter.default.post(
//                    name: .navigateToReport,
//                    object: reportId
//                )
//            }
//        default:
//            break
//        }
//        
//        completionHandler()
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        // Show notifications even when app is in foreground
//        completionHandler([.alert, .sound, .badge])
//    }
//}
//
//extension Notification.Name {
//    static let navigateToReport = Notification.Name("navigateToReport")
//}
