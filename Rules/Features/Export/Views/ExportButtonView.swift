//ExportButtonView.swift
import SwiftUI
import UIKit

struct ExportButtonView: View {
    let items: [String]
    let title: String
    let category: String
    
    @State private var showingError = false
    @State private var showShareSheet = false
    private let exporter = PDFExporter()
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue

    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic:  return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach:    return ThemeColors.beachTheme
        case .desert:   return ThemeColors.desertTheme
        case .forest:   return ThemeColors.forestTheme
        }
    }
    private var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667
    }
    
    @State private var pdfDataToShare: Data?
    
    var body: some View {
        Button(action: exportToPDF) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: isSmallDevice ? 18 : 20))
                Text(LocalizedStringKey("export.pdf.button"))
            }
            .padding()
            .background(themeColors.accent)
            .foregroundColor(themeColors.lightText)
            .cornerRadius(10)
            .shadow(color: themeColors.cardShadow, radius: 5)
        }
        .alert(Text(LocalizedStringKey("export.error.title")),
               isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(LocalizedStringKey("export.error.message"))
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfDataToShare {
                ActivityView(activityItems: [data])
            } else {
                Text("No PDF data available")
            }
        }
    }
    
    private func exportToPDF() {
        // Dodaj niewielkie opóźnienie, aby dane z listy mogły się zaktualizować
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let exportData = PDFExporter.ExportData(
                title: title,
                items: items,
                category: category,
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
}
