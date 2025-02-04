//ChatListView.swift
import SwiftUI

struct ChatListView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Lista czatów")
            }
            .navigationTitle("Czaty")
        }
    }
}
