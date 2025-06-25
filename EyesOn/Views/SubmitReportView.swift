//
//  SubmitReportView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI

struct SubmitReportView: View {
    @StateObject private var viewModel = ReportViewModel()
    @State private var showingImageActionSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Selection Section - THIS WAS MISSING!
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        CategorySelectionView(selectedCategory: $viewModel.selectedCategory)
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.description)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("Describe what you observed in detail")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    

                    
                    // Location Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            
                            Text("Your current location will be used")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Submit Button
                    Button(action: {
                        Task { await viewModel.submitReport() }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Submit Report")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSubmitDisabled ? Color.gray : (viewModel.selectedCategory?.color ?? Color.red))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitDisabled)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationTitle("Report Activity")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Report Submitted", isPresented: $viewModel.reportSubmittedSuccessfully) {
                Button("OK") {
                    viewModel.reportSubmittedSuccessfully = false
                    viewModel.resetForm()
                }
            } message: {
                Text("Your report has been submitted for review. Thank you for keeping the community safe!")
            }
        }
    }
    
    private var isSubmitDisabled: Bool {
        viewModel.selectedCategory == nil || viewModel.description.isEmpty || viewModel.isLoading
    }
}
