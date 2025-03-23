//  MyChecklistExportButtonView.swift
import SwiftUI
import Darwin

struct TravelChecklistExportButtonView: View {
    let items: [String] = []
    
    @State private var showingError = false
    @State private var showShareSheet = false
    @State private var pdfDataToShare: Data?
    private let exporter = PDFExporter()
    
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    var body: some View {
        Button(action: exportTravelChecklist) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: isSmallDevice ? 18 : 20))
                Text("export_travel_checklist".appLocalized)
            }
            .padding()
            .background(Color("AccentColor"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .alert("Export error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfDataToShare {
                ActivityView(activityItems: [data])
            } else {
                Text("No PDF data available")
            }
        }
    }
    
    private func exportTravelChecklist() {
        let exportData = PDFExporter.ExportData(
            title: "Travel Checklist",
            items: items,
            category: "Standard Checklist",
            date: Date()
        )
        
        guard let data = exporter.generatePDF(data: exportData) else {
            showingError = true
            return
        }
        pdfDataToShare = data
        showShareSheet = true
    }
}
