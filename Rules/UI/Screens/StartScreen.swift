import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit

struct MainView: View {
    let bannerID = "ca-app-pub-5307701268996147/4702587401"
    @State private var shouldShowAd = false
    @State private var animateTravel = false
    @State private var animateRules = false
    @State private var isPulsating = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("isMusicEnabled") var isMusicEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme = ThemeStyle.classic.rawValue
    @StateObject private var languageManager = LanguageManager.shared
    
    private var themeColors: ThemeColors {
        switch ThemeStyle(rawValue: selectedTheme) ?? .classic {
        case .classic: return ThemeColors.classicTheme
        case .mountain: return ThemeColors.mountainTheme
        case .beach: return ThemeColors.beachTheme
        case .desert: return ThemeColors.desertTheme
        case .forest: return ThemeColors.forestTheme
        }
    }
    
    private var deviceType: DeviceType {
        let height = UIScreen.main.bounds.height
        switch height {
        case 0...568: return .iPhoneSE1
        case 569...667: return .iPhone8
        case 668...736: return .iPhone8Plus
        case 737...812: return .iPhoneX
        case 813...896: return .iPhone11
        case 897...926: return .iPhone12
        default: return .iPhone13ProMax
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundImage(isDarkMode: isDarkMode, selectedTheme: selectedTheme)
                
                VStack(spacing: deviceType.spacing) {
                    TitleSection(
                        animateTravel: $animateTravel,
                        animateRules: $animateRules,
                        themeColors: themeColors,
                        deviceType: deviceType
                    )
                    
                    if deviceType != .iPhoneSE1 {
                        DescriptionSection(
                            isPulsating: $isPulsating,
                            themeColors: themeColors,
                            deviceType: deviceType
                        )
                    }
                    
                    Spacer()
                }
                .padding(.top, deviceType.topPadding)
            }
            .onAppear {
                startAnimations()
                playMusicIfEnabled()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func startAnimations() {
        withAnimation {
            animateTravel = true
            animateRules = true
        }
    }
    
    private func playMusicIfEnabled() {
        if isMusicEnabled {
            playBackgroundMusic()
        }
    }
}

enum DeviceType {
    case iPhoneSE1
    case iPhone8
    case iPhone8Plus
    case iPhoneX
    case iPhone11
    case iPhone12
    case iPhone13ProMax
    
    var fontSize: CGFloat {
        switch self {
        case .iPhoneSE1: return 32
        case .iPhone8: return 36
        case .iPhone8Plus: return 40
        case .iPhoneX: return 42
        case .iPhone11: return 44
        case .iPhone12: return 46
        case .iPhone13ProMax: return 50
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .iPhoneSE1: return 8
        case .iPhone8: return 12
        case .iPhone8Plus, .iPhoneX: return 16
        default: return 20
        }
    }
    
    var topPadding: CGFloat {
        switch self {
        case .iPhoneSE1: return 20
        case .iPhone8: return 30
        case .iPhone8Plus: return 40
        case .iPhoneX: return 50
        default: return 60
        }
    }
    
    var buttonSize: CGSize {
        switch self {
        case .iPhoneSE1: return CGSize(width: 160, height: 40)
        case .iPhone8: return CGSize(width: 180, height: 45)
        default: return CGSize(width: 200, height: 50)
        }
    }
}

struct BackgroundImage: View {
    let isDarkMode: Bool
    let selectedTheme: String
    
    @ViewBuilder
    var body: some View {
        if #available(iOS 14.0, *) {
            AsyncImage(url: URL(string: getBackgroundImageName())) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                    //.edgesIgnoringSafeArea(.all)
                    
                default:
                    Image(getBackgroundImageName())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    //.edgesIgnoringSafeArea(.all)
                        .ignoresSafeArea()
                }
            }
        } else {
            Image(getBackgroundImageName())
                .resizable()
                .aspectRatio(contentMode: .fill)
            // .edgesIgnoringSafeArea(.all)
                .ignoresSafeArea()
        }
    }
    
    private func getBackgroundImageName() -> String {
        let theme = ThemeStyle(rawValue: selectedTheme) ?? .classic
        switch theme {
        case .classic: return isDarkMode ? "classic-bg-dark" : "classic-bg"
        case .mountain: return isDarkMode ? "mountain-bg-dark" : "mountain-bg"
        case .beach: return isDarkMode ? "beach-bg-dark" : "beach-bg"
        case .desert: return isDarkMode ? "desert-bg-dark" : "desert-bg"
        case .forest: return isDarkMode ? "forest-bg-dark" : "forest-bg"
        }
    }
}

struct TitleSection: View {
    @Binding var animateTravel: Bool
    @Binding var animateRules: Bool
    let themeColors: ThemeColors
    let deviceType: DeviceType
    
    var body: some View {
        VStack(spacing: deviceType.spacing) {
            Spacer()
            
            AnimatedText(
                text: "TRAVEL".appLocalized,
                offset: animateTravel ? 0 : -100,
                opacity: animateTravel ? 1 : 0,
                delay: 1,
                themeColors: themeColors,
                fontSize: deviceType.fontSize
            )
            
            AnimatedText(
                text: "RULES".appLocalized,
                offset: animateRules ? 0 : 100,
                opacity: animateRules ? 1 : 0,
                delay: 2,
                themeColors: themeColors,
                fontSize: deviceType.fontSize
            )
        }
        .padding(.bottom, deviceType.spacing * 2)
    }
}

struct AnimatedText: View {
    let text: String
    let offset: CGFloat
    let opacity: Double
    let delay: Double
    let themeColors: ThemeColors
    let fontSize: CGFloat
    
    var body: some View {
        Text(text)
            .font(.custom("Lato-Bold", size: fontSize, relativeTo: .title))
            .fontWeight(.bold)
            .foregroundColor(themeColors.primaryText)
            .frame(maxWidth: .infinity)
            .offset(x: offset)
            .opacity(opacity)
            .animation(.easeOut(duration: 1).delay(delay), value: offset)
            .accessibility(label: Text(text))
    }
}

struct DescriptionSection: View {
    @Binding var isPulsating: Bool
    let themeColors: ThemeColors
    let deviceType: DeviceType
    
    var body: some View {
        VStack(spacing: deviceType.spacing) {
            Text("app_description".appLocalized)
                .font(.custom("Lato-Bold", size: deviceType.fontSize * 0.4))
                .fontWeight(.bold)
                .foregroundColor(themeColors.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(maxWidth: deviceType == .iPhoneSE1 ? 280 : 340)
            
            NavigationLink(destination: NextView()) {
                StartButton(
                    isPulsating: $isPulsating,
                    themeColors: themeColors,
                    deviceType: deviceType
                )
            }
        }
    }
}

struct StartButton: View {
    @Binding var isPulsating: Bool
    let themeColors: ThemeColors
    let deviceType: DeviceType
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .foregroundColor(themeColors.secondary)
            .frame(width: deviceType.buttonSize.width, height: deviceType.buttonSize.height)
            .overlay(
                Text("lets_go".appLocalized)
                    .font(.custom("Lato-Bold", size: deviceType.fontSize * 0.5))
                    .foregroundColor(themeColors.primaryText)
            )
            .scaleEffect(isPulsating ? 0.95 : 0.99)
            .shadow(color: themeColors.cardShadow, radius: 5, x: 0, y: 2)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsating = true
                }
            }
            .accessibility(label: Text("start_button".appLocalized))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environment(\.colorScheme, .light)
    }
}
