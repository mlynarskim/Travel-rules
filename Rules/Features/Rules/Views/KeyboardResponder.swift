import Foundation
import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
    private var center: NotificationCenter
    private var keyboardShow: AnyCancellable?
    private var keyboardHide: AnyCancellable?
    
    init(center: NotificationCenter = .default) {
        self.center = center
        setupPublishers()
    }
    
    private func setupPublishers() {
        keyboardShow = center.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentHeight, on: self)
        
        keyboardHide = center.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat.zero }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentHeight, on: self)
    }
}

