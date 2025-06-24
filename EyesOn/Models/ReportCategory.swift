
//
//  ReportCategory.swift
//  EyesOn
//
//  Created by Avital on 23/06/2025.
//

import SwiftUI

enum ReportCategory: String, CaseIterable, Identifiable, Codable {
    case theft = "theft"
    case vandalism = "vandalism"
    case suspiciousActivity = "suspicious_activity"
    case harassment = "harassment"
    case poorlyLit = "poorly_lit"
    case emergency = "emergency"
    case assault = "assault"
    case drugsAlcohol = "drugs_alcohol"
    case noise = "noise"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .theft:
            return "Theft"
        case .vandalism:
            return "Vandalism"
        case .suspiciousActivity:
            return "Suspicious Activity"
        case .harassment:
            return "Harassment"
        case .poorlyLit:
            return "Poor Lighting"
        case .emergency:
            return "Emergency"
        case .assault:
            return "Assault"
        case .drugsAlcohol:
            return "Drugs/Alcohol"
        case .noise:
            return "Noise Complaint"
        case .other:
            return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .theft:
            return "bag.fill"
        case .vandalism:
            return "hammer.fill"
        case .suspiciousActivity:
            return "eye.fill"
        case .harassment:
            return "person.2.fill"
        case .poorlyLit:
            return "lightbulb.slash.fill"
        case .emergency:
            return "exclamationmark.triangle.fill"
        case .assault:
            return "figure.walk.circle.fill"
        case .drugsAlcohol:
            return "pills.fill"
        case .noise:
            return "speaker.wave.3.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .theft:
            return .orange
        case .vandalism:
            return .purple
        case .suspiciousActivity:
            return .yellow
        case .harassment:
            return .pink
        case .poorlyLit:
            return .gray
        case .emergency:
            return .red
        case .assault:
            return .red
        case .drugsAlcohol:
            return .brown
        case .noise:
            return .blue
        case .other:
            return .secondary
        }
    }
    
    var severity: ReportSeverity {
        switch self {
        case .emergency, .assault:
            return .critical
        case .theft, .harassment:
            return .high
        case .vandalism, .suspiciousActivity, .drugsAlcohol:
            return .medium
        case .poorlyLit, .noise, .other:
            return .low
        }
    }
    
    var description: String {
        switch self {
        case .theft:
            return "Report stolen items, pickpocketing, or break-ins"
        case .vandalism:
            return "Property damage, graffiti, or destruction"
        case .suspiciousActivity:
            return "Unusual behavior or concerning activities"
        case .harassment:
            return "Verbal or physical intimidation"
        case .poorlyLit:
            return "Areas with inadequate lighting for safety"
        case .emergency:
            return "Immediate danger requiring urgent attention"
        case .assault:
            return "Physical violence or threats of violence"
        case .drugsAlcohol:
            return "Public intoxication or drug-related activity"
        case .noise:
            return "Excessive noise disturbing the peace"
        case .other:
            return "Safety concerns not covered by other categories"
        }
    }
}

enum ReportSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var priority: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        case .critical:
            return 4
        }
    }
}
