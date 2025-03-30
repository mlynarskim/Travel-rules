import SwiftUI
import GoogleMobileAds
import Darwin

struct AdBannerView: UIViewRepresentable {
    let adUnitID: String
    private let refreshInterval: TimeInterval = 60 // Czas w sekundach
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Reklama załadowana")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Błąd ładowania reklamy: \(error.localizedDescription)")
        }
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeMediumRectangle)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.backgroundColor = .clear
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            bannerView.load(Request())
        }
        
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
}
