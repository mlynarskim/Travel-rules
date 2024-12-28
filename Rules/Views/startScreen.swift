import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit

struct ContentView: View {
    // MARK: - Properties
    @State private var isPulsating = false
    @State private var animateTravel = false
    @State private var animateRules = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("isMusicEnabled") var isMusicEnabled = true
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundImage(isDarkMode: isDarkMode)
                
                VStack {
                    TitleSection(
                        animateTravel: $animateTravel,
                        animateRules: $animateRules
                    )
                    
                    Spacer()
                    
                    DescriptionSection(isPulsating: $isPulsating)
                }
            }
            .onAppear {
                startAnimations()
                playMusicIfEnabled()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Private Methods
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

// MARK: - Components
struct BackgroundImage: View {
    let isDarkMode: Bool
    
    var body: some View {
        Image(isDarkMode ? "imageDark" : "Image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}

struct TitleSection: View {
    @Binding var animateTravel: Bool
    @Binding var animateRules: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            AnimatedText(
                text: "TRAVEL".appLocalized,
                offset: animateTravel ? 0 : -100,
                opacity: animateTravel ? 1 : 0,
                delay: 1
            )
            .padding(.top, 80)
            
            AnimatedText(
                text: "RULES".appLocalized,
                offset: animateRules ? 0 : 100,
                opacity: animateRules ? 1 : 0,
                delay: 2
            )
            .padding(.bottom, 60)
        }
    }
}

struct AnimatedText: View {
    let text: String
    let offset: CGFloat
    let opacity: Double
    let delay: Double
    
    var body: some View {
        Text(text)
            .font(.custom("Lato-Bold", size: 50))
            .fontWeight(.bold)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .offset(x: offset)
            .opacity(opacity)
            .animation(.easeOut(duration: 1).delay(delay), value: offset)
    }
}

struct DescriptionSection: View {
    @Binding var isPulsating: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("An app for everyone who loves the lifestyle of living on wheels. You will find lots of rules to help you prepare for life in an RV, caravan, plane, train, boat or foot.".appLocalized)
                .font(.custom("Lato-Bold", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: 340)
            
            NavigationLink(destination: NextView()) {
                StartButton(isPulsating: $isPulsating)
            }
        }
    }
}

struct StartButton: View {
    @Binding var isPulsating: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .foregroundColor(Color(hex: "#DDAA4F"))
            .frame(width: 200, height: 50)
            .padding(.all, 15)
            .overlay(
                Text("Let's go!".appLocalized)
                    .font(.custom("Lato-Bold", size: 24))
                    .foregroundColor(.black)
            )
            .scaleEffect(isPulsating ? 0.95 : 0.99)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsating = true
                }
            }
    }
}
