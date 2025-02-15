import Foundation
import SwiftUI

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            currentHeight = keyboardFrame.cgRectValue.height
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        currentHeight = 0
    }
}
