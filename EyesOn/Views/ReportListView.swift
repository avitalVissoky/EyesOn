//
//  ReportListView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI
import CoreLocation

struct ReportListView: View {
    @StateObject private var viewModel = ReportsListViewModel()
    @State private var selectedCategory: ReportCategory?
    @State private var showingCategoryFilter = false
    @State private var selectedReport: Report?
    @State private var reportScope: ReportScope = .all
    
    enum ReportScope: String, CaseIterable {
        case all = "All Reports"
        case mine = "My Reports"
        
        var icon: String {
            switch self {
            case .all: return "globe"
            case .mine: return "person.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScopeSelectorView(selectedScope: $reportScope)
                
                if reportScope == .all && !viewModel.allReports.isEmpty {
                    FilterBarView(
                        selectedCategory: $selectedCategory,
                        onFilterTap: { showingCategoryFilter = true },
                        totalReports: viewModel.allReports.count,
                        filteredReports: filteredReports.count
                    )
                }
                
                if viewModel.isLoading {
                    LoadingView()
                } else if filteredReports.isEmpty {
                    EmptyStateView(
                        reportScope: reportScope,
                        hasReports: !viewModel.allReports.isEmpty,
                        selectedCategory: selectedCategory
                    ) {
                        selectedCategory = nil
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredReports) { report in
                                ReportCardView(
                                    report: report,
                                    isMyReport: report.userId == viewModel.currentUserId,
                                    showUserIndicator: reportScope == .all
                                ) {
                                    selectedReport = report
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadReports()
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if reportScope == .all {
                        Button(action: { showingCategoryFilter = true }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadReports()
            }
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterSheet(
                    selectedCategory: $selectedCategory,
                    onFilterChange: { _ in }
                )
            }
            .sheet(item: $selectedReport) { report in
                ReportDetailSheet(report: report)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var filteredReports: [Report] {
        let baseReports = reportScope == .all ? viewModel.allReports : viewModel.myReports
        
        if let category = selectedCategory {
            return baseReports.filter { $0.category == category }
        }
        return baseReports
    }
}

struct ScopeSelectorView: View {
    @Binding var selectedScope: ReportListView.ReportScope
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ReportListView.ReportScope.allCases, id: \.rawValue) { scope in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedScope = scope
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: scope.icon)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(scope.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedScope == scope ? .white : .primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedScope == scope ? Color.blue : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Divider
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4))
        }
    }
}
struct FilterBarView: View {
    @Binding var selectedCategory: ReportCategory?
    let onFilterTap: () -> Void
    let totalReports: Int
    let filteredReports: Int
    
    var body: some View {
        HStack {
            Button(action: onFilterTap) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16, weight: .medium))
                    
                    if let category = selectedCategory {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption)
                                .foregroundColor(category.color)
                            Text(category.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    } else {
                        Text("All Categories")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            if selectedCategory != nil {
                Button(action: {
                    selectedCategory = nil
                }) {
                    Text("Clear")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4))
                .offset(y: 20)
        )
    }
}

struct ReportCardView: View {
    let report: Report
    let isMyReport: Bool
    let showUserIndicator: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(report.category.color.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: report.category.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(report.category.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.category.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            SeverityBadge(severity: report.category.severity)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeAgoString(from: report.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if showUserIndicator && isMyReport {
                            Text("Your Report")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                
                Text(report.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(distanceString(from: report))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: report.status)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isMyReport ? Color.blue.opacity(0.3) : Color(.systemGray5), lineWidth: isMyReport ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func distanceString(from report: Report) -> String {
        guard let userLocation = LocationManager.shared.currentLocation else {
            return "Location unknown"
        }
        
        let reportLocation = CLLocation(latitude: report.latitude, longitude: report.longitude)
        let distance = userLocation.distance(from: reportLocation)
        
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            return "\(String(format: "%.1f", distance / 1000))km away"
        }
    }
}

struct SeverityBadge: View {
    let severity: ReportSeverity
    
    var body: some View {
        Text(severity.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severity.color.opacity(0.2))
            .foregroundColor(severity.color)
            .clipShape(Capsule())
    }
}

struct StatusBadge: View {
    let status: Report.ReportStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
}


struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading nearby reports...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct EmptyStateView: View {
    let reportScope: ReportListView.ReportScope
    let hasReports: Bool
    let selectedCategory: ReportCategory?
    let onClearFilter: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyIcon)
                .font(.system(size: 60))
                .foregroundColor(selectedCategory?.color ?? .gray)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(emptyMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if selectedCategory != nil {
                Button(action: onClearFilter) {
                    Text("Show All Reports")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyIcon: String {
        switch reportScope {
        case .all:
            return selectedCategory?.icon ?? "exclamationmark.triangle"
        case .mine:
            return "person.crop.circle.badge.plus"
        }
    }
    
    private var emptyTitle: String {
        switch reportScope {
        case .all:
            if let category = selectedCategory {
                return "No \(category.displayName) Reports"
            } else if hasReports {
                return "No Reports in This Category"
            } else {
                return "No Reports Nearby"
            }
        case .mine:
            if let category = selectedCategory {
                return "No \(category.displayName) Reports from You"
            } else {
                return "No Reports from You"
            }
        }
    }
    
    private var emptyMessage: String {
        switch reportScope {
        case .all:
            if selectedCategory != nil {
                return "There are no reports in this category. Try selecting a different category or clear the filter to see all reports."
            } else {
                return "There are no safety reports in your area at the moment. This is good news! Your community appears to be safe."
            }
        case .mine:
            if selectedCategory != nil {
                return "You haven't submitted any reports in this category yet. Help keep your community safe by reporting incidents you observe."
            } else {
                return "You haven't submitted any reports yet. Help keep your community safe by reporting safety incidents you observe."
            }
        }
    }
}
