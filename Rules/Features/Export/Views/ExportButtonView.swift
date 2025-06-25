// ExportButtonView.swift
import SwiftUI
import UIKit
import Darwin

struct ExportButtonView: View {
    let items: [String]
    let title: String
    let category: String
    let fileName: String
    
    @State private var showingError = false
    @State private var showShareSheet = false
    @State private var fileURLToShare: URL?
    
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
            if let url = fileURLToShare {
                ActivityView(activityItems: [url])
            } else {
                Text("No PDF data available")
            }
        }
    }
    
    private func exportToPDF() {
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
            // Zapisz PDF do pliku tymczasowego z zachowaniem nazwy
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            do {
                try data.write(to: tmpURL)
                fileURLToShare = tmpURL
                showShareSheet = true
            } catch {
                showingError = true
            }
        }
    }
}
