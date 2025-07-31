//
//  CategorySelectionView.swift
//  EyesOn
//
//  Created by Avital on 23/06/2025.
//

import SwiftUI

struct CategorySelectionView: View {
    @Binding var selectedCategory: ReportCategory?
    @State private var showingCategoryDetail: ReportCategory?
    
    // Create a 3-column grid for better symmetry
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What type of incident are you reporting?")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(ReportCategory.allCases) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                    .onTapGesture {
                        showingCategoryDetail = category
                    }
                }
            }
            
            if let selected = selectedCategory {
                SelectedCategoryInfo(category: selected)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
        .sheet(item: $showingCategoryDetail) { category in
            CategoryDetailView(category: category, selectedCategory: $selectedCategory)
        }
    }
}

struct CategoryCard: View {
    let category: ReportCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon container with improved design
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(category.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(category.color.opacity(isSelected ? 1.0 : 0.3), lineWidth: isSelected ? 3 : 1.5)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(category.color)
                }
                
                // Category name with better spacing
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Improved severity indicator
                HStack(spacing: 2) {
                    ForEach(1...4, id: \.self) { level in
                        Circle()
                            .fill(level <= category.severity.priority ? category.severity.color : Color.gray.opacity(0.2))
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 140) // Fixed height for consistency
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color.opacity(0.08) : Color(.systemBackground))
                    .stroke(
                        isSelected ? category.color.opacity(0.8) : Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .shadow(
                        color: isSelected ? category.color.opacity(0.3) : .black.opacity(0.05),
                        radius: isSelected ? 8 : 3,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SelectedCategoryInfo: View {
    let category: ReportCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(category.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SeverityBadge(severity: category.severity)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(category.color)
                }
            }
            
            Text(category.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(category.color.opacity(0.05))
                .stroke(category.color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CategoryDetailView: View {
    let category: ReportCategory
    @Binding var selectedCategory: ReportCategory?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(category.color)
                    }
                    
                    Text(category.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    SeverityBadge(severity: category.severity)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(category.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Examples (you can customize this per category)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Examples")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(examplesForCategory(category), id: \.self) { example in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(category.color)
                                    .padding(.top, 6)
                                
                                Text(example)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Select Button
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Select This Category")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(category.color)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
            .navigationTitle("Report Category")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    private func examplesForCategory(_ category: ReportCategory) -> [String] {
        switch category {
        case .theft:
            return ["Stolen bike or belongings", "Pickpocketing incident", "Break-in or burglary"]
        case .vandalism:
            return ["Graffiti on buildings", "Broken windows", "Damaged public property"]
        case .suspiciousActivity:
            return ["Person acting strangely", "Unusual loitering", "Potential drug dealing"]
        case .harassment:
            return ["Verbal threats", "Following or stalking", "Unwanted contact"]
        case .poorlyLit:
            return ["Broken street lights", "Dark alleyways", "Inadequate lighting in parking areas"]
        case .emergency:
            return ["Medical emergency", "Fire or smoke", "Immediate danger to public"]
        case .assault:
            return ["Physical attack", "Domestic violence", "Sexual assault"]
        case .drugsAlcohol:
            return ["Public intoxication", "Drug use in public", "Discarded needles"]
        case .noise:
            return ["Loud parties", "Construction noise", "Disturbing music"]
        case .other:
            return ["General safety concerns", "Unusual incidents", "Other community issues"]
        }
    }
}

#Preview {
    CategorySelectionView(selectedCategory: .constant(nil))
        .padding()
}
