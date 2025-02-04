import UIKit
import PDFKit

class PDFExporter {
    private let configuration = PDFConfiguration()
    
    struct ExportData {
        let title: String
        let items: [String]
        let category: String
        let date: Date
    }
    
    func generatePDF(data: ExportData) -> Data? {
        let metadata = [
            kCGPDFContextCreator: Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Travel Rules",
            kCGPDFContextTitle: data.title,
            kCGPDFContextAuthor: "Travel Rules App"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = metadata as [String: Any]
        
        let pdfRect = CGRect(origin: .zero, size: configuration.pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: pdfRect, format: format)
        
        return renderer.pdfData { context in
            var currentPage = 1
            var yPosition = configuration.margins.top
            
            func addNewPage() {
                context.beginPage()
                yPosition = configuration.margins.top
                addHeader(page: currentPage)
                currentPage += 1
            }
            
            func addHeader(page: Int) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                let headerText = "\(dateFormatter.string(from: data.date)) | \(data.category)"
                
                // App icon
                if let logo = UIImage(named: "AppIcon") {
                    let logoSize = CGSize(width: 40, height: 40)
                    let logoRect = CGRect(x: configuration.margins.left,
                                        y: configuration.margins.top,
                                        width: logoSize.width,
                                        height: logoSize.height)
                    logo.draw(in: logoRect)
                }
                
                // Header text
                let headerPoint = CGPoint(x: configuration.margins.left + 50,
                                        y: configuration.margins.top + 15)
                headerText.draw(at: headerPoint, withAttributes: configuration.styles.header)
                
                // Page number
                let pageText = String(format: NSLocalizedString("pdf.page", comment: ""), page)
                let pageTextSize = pageText.size(withAttributes: configuration.styles.pageNumber)
                let pagePoint = CGPoint(
                    x: configuration.pageSize.width - configuration.margins.right - pageTextSize.width,
                    y: configuration.pageSize.height - configuration.margins.bottom
                )
                pageText.draw(at: pagePoint, withAttributes: configuration.styles.pageNumber)
                
                yPosition += 60
            }
            
            addNewPage()
            
            // Title
            let titleRect = CGRect(
                x: configuration.margins.left,
                y: yPosition,
                width: configuration.pageSize.width - configuration.margins.left - configuration.margins.right,
                height: 30
            )
            (data.title as NSString).draw(in: titleRect, withAttributes: configuration.styles.title)
            
            yPosition += 40
            
            // Content
            for item in data.items {
                let bulletPoint = "• "
                let fullText = bulletPoint + item
                
                if yPosition > configuration.pageSize.height - configuration.margins.bottom - 30 {
                    addNewPage()
                }
                
                let itemRect = CGRect(
                    x: configuration.margins.left,
                    y: yPosition,
                    width: configuration.pageSize.width - configuration.margins.left - configuration.margins.right,
                    height: 25
                )
                (fullText as NSString).draw(in: itemRect, withAttributes: configuration.styles.body)
                
                yPosition += 25
            }
        }
    }
}
