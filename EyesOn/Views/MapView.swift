//
//  MapView.swift
//  EyesOn
//
//  Created by Avital on 22/06/2025.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedReport: Report?
    @State private var mapType: MKMapType = .standard
    @State private var showingCategoryFilter = false
    @State private var selectedCategoryFilter: ReportCategory?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main Map
                MapViewRepresentable(
                    region: $viewModel.region,
                    mapType: $mapType,
                    reports: viewModel.nearbyReports,
                    onReportTap: { report in
                        selectedReport = report
                    }
                )
                .edgesIgnoringSafeArea(.top)
                
                // Overlay Controls
                VStack {
                    // Top Controls
                    HStack {
                        // Category Filter Button
                        Button(action: {
                            showingCategoryFilter = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 14, weight: .medium))
                                if let filter = selectedCategoryFilter {
                                    Text(filter.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                } else {
                                    Text("Filter")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                            )
                        }
                        
                        Spacer()
                        
                        // Map Style Toggle
                        MapStyleToggle(currentMapType: $mapType)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom Controls
                    HStack {
                        CategoryLegendView()
                        
                        Spacer()
                        
                        // Location Button
                        Button(action: {
                            viewModel.refreshLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for tab bar
                }
                
                // Loading Indicator
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        
                        Text("Loading reports...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 4)
                    )
                }
            }
            .navigationTitle("Nearby Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.loadReports()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadReports()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedReport) { report in
                ReportDetailSheet(report: report)
            }
            .sheet(isPresented: $showingCategoryFilter) {
                CategoryFilterSheet(
                    selectedCategory: $selectedCategoryFilter,
                    onFilterChange: { category in
                        viewModel.filterReportsByCategory(category)
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MapStyleToggle: View {
    @Binding var currentMapType: MKMapType
    
    var body: some View {
        Menu {
            Button(action: {
                currentMapType = .standard
            }) {
                Label("Standard", systemImage: "map")
            }
            
            Button(action: {
                currentMapType = .satellite
            }) {
                Label("Satellite", systemImage: "globe.americas")
            }
            
            Button(action: {
                currentMapType = .hybrid
            }) {
                Label("Hybrid", systemImage: "map.circle")
            }
            
            Button(action: {
                currentMapType = .satelliteFlyover
            }) {
                Label("Satellite 3D", systemImage: "globe.desk")
            }
        } label: {
            Image(systemName: "map")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(12)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
        }
    }
}

struct CategoryLegendView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Legend")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(ReportCategory.allCases.prefix(8)) { category in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 16, height: 16)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Severity indicator
                            Text(category.severity.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(category.severity.color.opacity(0.2))
                                .foregroundColor(category.severity.color)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - MapViewRepresentable
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    let reports: [Report]
    let onReportTap: (Report) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Basic map configuration
        mapView.mapType = .standard
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.showsTraffic = false
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        // Enable all interactions including zoom
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false
        
        // Remove restrictive camera zoom range to allow free zooming
        mapView.cameraZoomRange = nil
        
        // Set initial region immediately
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type if changed
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        
        // Check if region needs updating (be more lenient to allow user zoom)
        let currentRegion = mapView.region
        let regionChanged = abs(currentRegion.center.latitude - region.center.latitude) > 0.05 ||
                           abs(currentRegion.center.longitude - region.center.longitude) > 0.05
        
        // Only update region if there's a significant center change, not zoom level changes
        if regionChanged {
            var newRegion = region
            // Preserve user's zoom level if they've zoomed manually
            if currentRegion.span.latitudeDelta > 0.001 && currentRegion.span.longitudeDelta > 0.001 {
                // Use current zoom level if it's reasonable
                newRegion.span = currentRegion.span
            }
            mapView.setRegion(newRegion, animated: true)
        }
        
        // Update annotations
        context.coordinator.updateAnnotations(mapView: mapView, reports: reports)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapViewRepresentable
        private var currentAnnotations: [ReportAnnotation] = []
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func updateAnnotations(mapView: MKMapView, reports: [Report]) {
            // Only update if reports actually changed
            let newAnnotationIds = Set(reports.map { $0.id })
            let currentAnnotationIds = Set(currentAnnotations.map { $0.report.id })
            
            if newAnnotationIds != currentAnnotationIds {
                // Remove existing report annotations (keep user location)
                let reportAnnotations = mapView.annotations.compactMap { $0 as? ReportAnnotation }
                mapView.removeAnnotations(reportAnnotations)
                
                // Add new annotations
                let newAnnotations = reports.map { ReportAnnotation(report: $0) }
                mapView.addAnnotations(newAnnotations)
                currentAnnotations = newAnnotations
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Only update the binding if the change was significant
            // This prevents interference with user zoom gestures
            let currentRegion = mapView.region
            let bindingRegion = parent.region
            
            let significantChange = abs(currentRegion.center.latitude - bindingRegion.center.latitude) > 0.001 ||
                                   abs(currentRegion.center.longitude - bindingRegion.center.longitude) > 0.001
            
            if significantChange {
                DispatchQueue.main.async {
                    self.parent.region = currentRegion
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Return nil for user location to use default blue dot
            guard let reportAnnotation = annotation as? ReportAnnotation else {
                return nil
            }
            
            let identifier = "ReportAnnotation"
            
            let annotationView: MKAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                dequeuedView.annotation = annotation
                annotationView = dequeuedView
            } else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.canShowCallout = false
            }
            
            // Create the custom pin view
            let pinView = ReportPinView(report: reportAnnotation.report)
            let hostingController = UIHostingController(rootView: pinView)
            hostingController.view.backgroundColor = .clear
            
            // Remove any existing subviews
            annotationView.subviews.forEach { $0.removeFromSuperview() }
            
            // Add the new pin view
            annotationView.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.centerXAnchor.constraint(equalTo: annotationView.centerXAnchor),
                hostingController.view.centerYAnchor.constraint(equalTo: annotationView.centerYAnchor, constant: -20),
                hostingController.view.widthAnchor.constraint(equalToConstant: 40),
                hostingController.view.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle tap on report annotation
            if let reportAnnotation = view.annotation as? ReportAnnotation {
                parent.onReportTap(reportAnnotation.report)
            }
            // Deselect immediately to allow repeated taps
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Handle any custom overlays if needed
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - ReportAnnotation
class ReportAnnotation: NSObject, MKAnnotation {
    let report: Report
    
    var coordinate: CLLocationCoordinate2D {
        return report.coordinate
    }
    
    var title: String? {
        return report.category.displayName
    }
    
    var subtitle: String? {
        return report.description
    }
    
    init(report: Report) {
        self.report = report
        super.init()
    }
}

// MARK: - ReportPinView
struct ReportPinView: View {
    let report: Report
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin body
            ZStack {
                Circle()
                    .fill(report.category.color)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                
                Circle()
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: 32, height: 32)
                
                Image(systemName: report.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Pin pointer
            Triangle()
                .fill(report.category.color)
                .frame(width: 12, height: 10)
                .offset(y: -2)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct ReportDetailSheet: View {
    let report: Report
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Category Header with enhanced design
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(report.category.color.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .stroke(report.category.color.opacity(0.3), lineWidth: 2)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: report.category.icon)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(report.category.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(report.category.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 8) {
                                Text("Severity:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(report.category.severity.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(report.category.severity.color.opacity(0.2))
                                    .foregroundColor(report.category.severity.color)
                                    .clipShape(Capsule())
                            }
                            
                            Text(report.status.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(report.status.color.opacity(0.2))
                                .foregroundColor(report.status.color)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(report.description)
                            .font(.body)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    // Image if available
                    if let imageUrl = report.imageUrl, !imageUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Photo Evidence", systemImage: "photo")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let localImage = FirebaseService.shared.loadLocalImage(path: imageUrl) {
                                Image(uiImage: localImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 150)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo.badge.exclamationmark")
                                                .font(.title)
                                                .foregroundColor(.secondary)
                                            Text("Image not available")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    )
                            }
                        }
                    }
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Report Details", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            DetailRow(
                                icon: "location.fill",
                                iconColor: .blue,
                                title: "Location",
                                value: "Lat: \(String(format: "%.4f", report.latitude)), Lng: \(String(format: "%.4f", report.longitude))"
                            )
                            
                            DetailRow(
                                icon: "clock.fill",
                                iconColor: .orange,
                                title: "Reported",
                                value: report.timestamp.formatted(date: .abbreviated, time: .shortened)
                            )
                            
                            DetailRow(
                                icon: "person.fill",
                                iconColor: .purple,
                                title: "Report ID",
                                value: String(report.id.prefix(8)).uppercased()
                            )
                            
                            if let moderatorId = report.moderatorId {
                                DetailRow(
                                    icon: "checkmark.shield.fill",
                                    iconColor: .green,
                                    title: "Reviewed by",
                                    value: String(moderatorId.prefix(8)).uppercased()
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - CategoryFilterSheet
struct CategoryFilterSheet: View {
    @Binding var selectedCategory: ReportCategory?
    let onFilterChange: (ReportCategory?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        selectedCategory = nil
                        onFilterChange(nil)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text("Show All Reports")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section("Filter by Category") {
                    ForEach(ReportCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category
                            onFilterChange(category)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: category.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(category.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.displayName)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    
                                    Text(category.severity.displayName)
                                        .font(.caption)
                                        .foregroundColor(category.severity.color)
                                }
                                
                                Spacer()
                                
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
