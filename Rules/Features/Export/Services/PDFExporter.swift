//PDFExporter.swift
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
                
                if let logo = UIImage(named: "AppIcon") {
                    let logoSize = CGSize(width: 40, height: 40)
                    let logoRect = CGRect(x: configuration.margins.left,
                                          y: configuration.margins.top,
                                          width: logoSize.width,
                                          height: logoSize.height)
                    logo.draw(in: logoRect)
                }
                
                let headerPoint = CGPoint(x: configuration.margins.left + 50,
                                          y: configuration.margins.top + 15)
                headerText.draw(at: headerPoint, withAttributes: configuration.styles.header)
                
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
            
            let titleRect = CGRect(
                x: configuration.margins.left,
                y: yPosition,
                width: configuration.pageSize.width - configuration.margins.left - configuration.margins.right,
                height: 30
            )
            (data.title as NSString).draw(in: titleRect, withAttributes: configuration.styles.title)
            
            yPosition += 40
            
            if data.items.isEmpty {
                let noItemsText = NSLocalizedString("No items to export.", comment: "")
                let noItemsRect = CGRect(
                    x: configuration.margins.left,
                    y: yPosition,
                    width: configuration.pageSize.width - configuration.margins.left - configuration.margins.right,
                    height: 25
                )
                (noItemsText as NSString).draw(in: noItemsRect, withAttributes: configuration.styles.body)
                yPosition += 25
            } else {
                if data.items.isEmpty {
                    let noItemsText = NSLocalizedString("No items to export.", comment: "")
                    let noItemsRect = CGRect(
                        x: configuration.margins.left,
                        y: yPosition,
                        width: configuration.pageSize.width - configuration.margins.left - configuration.margins.right,
                        height: 25
                    )
                    (noItemsText as NSString).draw(in: noItemsRect, withAttributes: configuration.styles.body)
                    yPosition += 25
                } else {
                    for item in data.items {
                        let itemHeight: CGFloat = 30
                        
                        let circleDiameter: CGFloat = 12
                        let circleX = configuration.margins.left
                        let circleY = yPosition + (itemHeight - circleDiameter) / 2
                        let circleRect = CGRect(x: circleX, y: circleY, width: circleDiameter, height: circleDiameter)
                        
                        let circlePath = UIBezierPath(ovalIn: circleRect)
                        UIColor.black.setStroke()
                        circlePath.lineWidth = 1.5
                        circlePath.stroke()
                        
                        let textX = configuration.margins.left + circleDiameter + 10
                        
                        var itemAttributes = configuration.styles.body
                        if let currentFont = itemAttributes[.font] as? UIFont {
                            let biggerFont = UIFont.systemFont(ofSize: currentFont.pointSize + 2)
                            itemAttributes[.font] = biggerFont
                        }
                        
                        let itemRect = CGRect(
                            x: textX,
                            y: yPosition,
                            width: configuration.pageSize.width - textX - configuration.margins.right,
                            height: itemHeight
                        )
                        (item as NSString).draw(in: itemRect, withAttributes: itemAttributes)
                        
                      
                        yPosition += itemHeight + 5 
                        if yPosition > configuration.pageSize.height - configuration.margins.bottom - 30 {
                            addNewPage()
                        }
                    }
                }

            }
        }
    }
}
