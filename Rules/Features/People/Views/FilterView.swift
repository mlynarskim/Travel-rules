//
//  Untitled.swift
//  Rules
//
//  Created by Mateusz Mlynarski on 17/01/2025.
//

import SwiftUI

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Text("Filtry")
            }
            .navigationTitle("Filtry")
            .navigationBarItems(trailing: Button("Gotowe") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
