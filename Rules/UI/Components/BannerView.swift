import SwiftUI
import GoogleMobileAds
import Darwin

struct AdBannerView: UIViewRepresentable {
    let adUnitID: String
    private let refreshInterval: TimeInterval = 20 // Czas w sekundach

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeMediumRectangle)
        bannerView.adUnitID = adUnitID
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
