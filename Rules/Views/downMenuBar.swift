import Foundation
import SwiftUI


struct downMenuBar: View {
    @State private var savedRules: [String] = []
    
    var body: some View {
            VStack {
                    HStack {
                NavigationLink(destination: AddRuleView()) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )        }
                NavigationLink(destination: TravelListView()) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )        }
//                NavigationLink(destination: NextView()) {
//                    RoundedRectangle(cornerRadius: 15)
//                        .padding(.all, 5)
//                        .foregroundColor(Color(hex: "#DDAA4F"))
//                        .frame(width: 80, height: 80)
//                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
//                        .overlay(
//                            Image(systemName: "house")
//                                .foregroundColor(.black)
//                                .font(.system(size: 40))
//                        )
//                }
                NavigationLink(destination: GPSView()) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "signpost.right.and.left")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )        }
                NavigationLink(destination: RulesListView(savedRules: savedRules)) {
                    RoundedRectangle(cornerRadius: 15)
                        .padding(.all, 5)
                        .foregroundColor(Color(hex: "#DDAA4F"))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Image(systemName: "list.star")
                                .foregroundColor(.black)
                                .font(.system(size: 40))
                        )}
            }
        }
    }
}
