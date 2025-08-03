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

<img alt="EyesOn_2" src="https://github.com/user-attachments/assets/a26a7819-cf40-40ce-a459-91d294d94274" style="height:400px;"/>
<img alt="EyesOn_1" src="https://github.com/user-attachments/assets/2fe34026-5c1f-46b5-8ae4-62f333843152" style="height:400px;"/>
<img alt="EyesOn_5" src="https://github.com/user-attachments/assets/7b944894-8519-4d4f-b66c-d2c7c0ef30b3" style="height:400px;"/>
<img alt="EyesOn_4" src="https://github.com/user-attachments/assets/3b296ab6-a927-430e-8213-81d4b6027194" style="height:400px;"/>
<img alt="EyesOn_3" src="https://github.com/user-attachments/assets/646ec37f-9ca2-44a8-96e7-b423c5db1a56" style="height:400px;"/>
<img alt="EyesOn_" src="https://github.com/user-attachments/assets/b85dbeee-d57b-4454-988b-e22d4547344f"style="height:400px;" />


## License
MIT License © 2025 Avital Vissoky
