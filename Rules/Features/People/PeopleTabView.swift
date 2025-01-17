//PeopleTabView.swift
import SwiftUI


struct PeopleTabView: View {
    var body: some View {
        NavigationView {
            PeopleMapView()
                .navigationTitle("Osoby w pobliżu")
        }
    }
}
