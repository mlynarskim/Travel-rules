import Foundation
import UIKit

struct PDFConfiguration {
    let pageSize: CGSize = CGSize(width: 595.2, height: 841.8)  // A4
    let margins: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
    
    struct TextStyles {
        let title: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .left
                return style
            }()
        ]
        
        let header: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        
        let body: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 6
                return style
            }()
        ]
        
        let pageNumber: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
    }
    
    let styles = TextStyles()
}
