import SwiftUI
import Foundation
import AVFoundation
import CoreLocation
import MapKit

struct ContentView: View {
    @State private var isPulsating = false
    @State private var animateRules = false
    @State private var animateTravel = false
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("isMusicEnabled") var isMusicEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Image(isDarkMode ? "imageDark" : "Image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                    Text("TRAVEL")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .font(.custom("Font LATO/Lato-Bold.ttf", size: 50))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80.0)
                        .offset(x: animateTravel ? 0 : -100)
                        .opacity(animateTravel ? 1 : 0)
                        .animation(.easeOut(duration: 1).delay(1), value: animateTravel)
                        .onAppear {
                            withAnimation {
                                animateTravel = true
                            }
                        }
                    Text("RULES")
                        .foregroundColor(.black)
                        .multilineTextAlignment(.trailing)
                        .font(.custom("Font LATO/Lato-Bold.ttf", size: 50))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 60)
                        .offset(x: animateRules ? 0 : 100)
                        .opacity(animateRules ? 1 : 0)
                        .animation(.easeOut(duration: 1).delay(2), value: animateRules)
                        .onAppear {
                            withAnimation {
                                animateRules = true
                            }
                        }
                    VStack{
                        Spacer()
                        Text("An app for everyone who loves the lifestyle of living on wheels. You will find 365 rules to help you prepare for life in an RV or caravan.")
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        //                            .frame(maxWidth: .infinity)
                        NavigationLink(destination: NextView()) {
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(Color(hex: "#DDAA4F"))
                                .frame(width: 200, height: 50)
                                .padding(.all, 15)
                            
                                .overlay(
                                    Text("Let's go!")
                                        .font(.custom("Lato Bold", size: 24))
                                        .foregroundColor(.black)
                                )
                                .scaleEffect(isPulsating ? 0.95 : 0.99)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                                        isPulsating = true
                                }
                            }
                        }
                    }
                }
            }
            .onAppear{
                if isMusicEnabled {
                    playBackgroundMusic()
                }

            }
        }
    }
}
