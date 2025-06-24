
//
//  ModeratorView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI

struct ModeratorView: View {
    @StateObject private var viewModel = ModeratorViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.pendingReports) { report in
                ModeratorReportRowView(report: report, viewModel: viewModel)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .navigationTitle("Pending Reports")
            .refreshable {
                await viewModel.loadPendingReports()
            }
            .task {
                await viewModel.loadPendingReports()
            }
            .overlay {
                if viewModel.pendingReports.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No Pending Reports")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("All reports have been reviewed.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct ModeratorReportRowView: View {
    let report: Report
    @ObservedObject var viewModel: ModeratorViewModel
    @State private var isApproving = false
    @State private var isRejecting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Report #\(String(report.id.prefix(8)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(timeAgoString(from: report.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text(report.description)
                .font(.body)
            
            // Image if available (local storage)
            if let imageUrl = report.imageUrl, !imageUrl.isEmpty {
                if let localImage = FirebaseService.shared.loadLocalImage(path: imageUrl) {
                    Image(uiImage: localImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .cornerRadius(8)
                        .overlay {
                            Text("Image unavailable")
                                .foregroundColor(.secondary)
                        }
                }
            }
            
            // Location
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                Text("Lat: \(report.latitude, specifier: "%.4f"), Lng: \(report.longitude, specifier: "%.4f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Approve Button
                Button(action: {
                    approveReport()
                }) {
                    HStack(spacing: 6) {
                        if isApproving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Approve")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isApproving ? Color.green.opacity(0.7) : Color.green)
                    )
                }
                .disabled(isApproving || isRejecting || viewModel.isProcessing(report.id))
                
                // Reject Button
                Button(action: {
                    rejectReport()
                }) {
                    HStack(spacing: 6) {
                        if isRejecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark")
                        }
                        Text("Reject")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isRejecting ? Color.red.opacity(0.7) : Color.red)
                    )
                }
                .disabled(isApproving || isRejecting || viewModel.isProcessing(report.id))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private func approveReport() {
        isApproving = true
        print("🟢 APPROVE button tapped for report: \(report.id)")
        
        Task {
            await viewModel.approveReport(report)
            await MainActor.run {
                isApproving = false
            }
        }
    }
    
    private func rejectReport() {
        isRejecting = true
        print("🔴 REJECT button tapped for report: \(report.id)")
        
        Task {
            await viewModel.rejectReport(report)
            await MainActor.run {
                isRejecting = false
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
