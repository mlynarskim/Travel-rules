import SwiftUI
import Combine

/// Reaguje na pojawienie się i zniknięcie klawiatury.
final class KeyboardResponder: ObservableObject {
    /// Aktualna wysokość klawiatury.
    @Published var currentHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init(center: NotificationCenter = .default) {
        // Łączymy dwa powiadomienia w jeden strumień.
        let willShow = center.publisher(for: UIResponder.keyboardWillShowNotification)
        let willHide = center.publisher(for: UIResponder.keyboardWillHideNotification)

        willShow
            .merge(with: willHide)
            .receive(on: RunLoop.main)          // zawsze na głównym wątku
            .sink { [weak self] notification in
                self?.updateHeight(with: notification)
            }
            .store(in: &cancellables)
    }

    private func updateHeight(with notification: Notification) {
        guard
            let userInfo  = notification.userInfo,
            let endFrame  = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration  = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        // Jeśli klawiatura się pokazuje - ustawiamy jej wysokość, w innym razie 0.
        let height = notification.name == UIResponder.keyboardWillShowNotification
            ? endFrame.height
            : 0

        // Animowana zmiana poza cyklem aktualizacji widoku.
        withAnimation(.easeOut(duration: duration)) {
            currentHeight = height
        }
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
