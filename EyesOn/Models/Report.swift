//
//  Report.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import Foundation
import SwiftUI
import CoreLocation

struct Report: Identifiable, Codable {
    let id: String
    let userId: String
    let category: ReportCategory
    let description: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    var status: ReportStatus
    let moderatorId: String?
    
    enum ReportStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
        
        var displayName: String {
            switch self {
            case .pending:
                return "Pending Review"
            case .approved:
                return "Approved"
            case .rejected:
                return "Rejected"
            }
        }
        
        var color: Color {
            switch self {
            case .pending:
                return .orange
            case .approved:
                return .green
            case .rejected:
                return .red
            }
        }
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         category: ReportCategory,
         description: String,
         latitude: Double,
         longitude: Double,
         timestamp: Date = Date(),
         status: ReportStatus = .pending,
         moderatorId: String? = nil) {
        self.id = id
        self.userId = userId
        self.category = category
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.status = status
        self.moderatorId = moderatorId
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case category
        case description
        case latitude
        case longitude
        case timestamp
        case status
        case moderatorId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        category = try container.decode(ReportCategory.self, forKey: .category)
        description = try container.decode(String.self, forKey: .description)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        status = try container.decode(ReportStatus.self, forKey: .status)
        moderatorId = try container.decodeIfPresent(String.self, forKey: .moderatorId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(category, forKey: .category)
        try container.encode(description, forKey: .description)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(moderatorId, forKey: .moderatorId)
    }
    
    // MARK: - MapKit Support
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
