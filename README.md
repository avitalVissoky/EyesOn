# 🛡️ EyesOn

**EyesOn** is a community safety app that empowers users to report suspicious activities, safety hazards, and criminal incidents in their area. It provides real-time location-based alerts, allows moderation of reports, and gives users tools to track and manage reports via map, list, and detailed views.

## 📱 Features

- 🗺️ **Map View** – Browse nearby reports with custom annotations and severity filters.
- 📝 **Submit Reports** – Easily report incidents with category, description, and location.
- 🔔 **Safety Notifications** – Receive alerts based on radius, category, and severity preferences.
- ✅ **Moderator Panel** – Approve or reject incoming reports as a trusted user.
- 🧭 **Location Tracking** – Smart filtering of reports based on proximity.
- 🔐 **Authentication** – Sign in anonymously or with email.
- 🎛️ **Settings Panel** – Manage account, alerts, themes, and privacy options.

## 🔧 Tech Stack

- **Language:** Swift + SwiftUI
- **Firebase:** Authentication & Realtime Database
- **Notifications:** `UserNotifications` + `BGAppRefreshTask`
- **Location:** `CoreLocation`, `MapKit`
- **UI:** Custom badges, modals, sheet filters, segmented controls

### Prerequisites

- Xcode 15+
- Swift 5.9+
- Firebase setup with:
  - Authentication (Anonymous + Email/Password)
  - Realtime Database

### Core Components
| Component                               | Description                                             |
| --------------------------------------- | ------------------------------------------------------- |
| `MainTabView.swift`                     | Tab-based UI container for all main screens             |
| `MapView.swift`                         | Displays report pins on map, supports filtering         |
| `SubmitReportView.swift`                | Form to submit new incident reports                     |
| `ReportListView.swift`                  | Browse and filter reports (all or mine)                 |
| `ModeratorView.swift`                   | Review, approve or reject pending reports               |
| `SettingsView.swift`                    | Manage alerts, themes, and account settings             |
| `FirebaseService.swift`                 | Firebase auth, data fetch/save, report moderation logic |
| `PollingNotificationManager.swift`      | Periodically checks for nearby reports and alerts       |
| `Report.swift` / `ReportCategory.swift` | Model definitions for reports and categories            |

## Screenshots

## License
MIT License © 2025 Avital Vissoky
