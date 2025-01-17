import SwiftUI
import UIKit

struct ExportButtonView: View {
    let items: [String]
    let title: String
    let category: String
    
    @State private var showingError = false
    private let exporter = PDFExporter()
    
    var body: some View {
        Button(action: exportToPDF) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text(LocalizedStringKey("export.pdf.button"))
            }
            .padding()
            .background(Color("AccentColor"))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .alert(Text(LocalizedStringKey("export.error.title")),
               isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(LocalizedStringKey("export.error.message"))
        }
    }
    
    private func exportToPDF() {
        let exportData = PDFExporter.ExportData(
            title: title,
            items: items,
            category: category,
            date: Date()
        )
        
        guard let pdfData = exporter.generatePDF(data: exportData) else {
            showingError = true
            return
        }
        
        shareSheet(with: [pdfData])
    }
    
    private func shareSheet(with items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            showingError = true
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.frame.width / 2,
                                                                        y: window.frame.height / 2,
                                                                        width: 0,
                                                                        height: 0)
        }
        
        rootVC.present(activityVC, animated: true)
    }
}

// Extension for Text localization
extension Text {
    func localized() -> Text {
        return Text(LocalizedStringKey(String(describing: self)))
    }
}
