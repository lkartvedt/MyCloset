//
//  MyClosetApp.swift
//  MyCloset
//
//  Created by Lindsey Kartvedt on 11/29/25.
//

import SwiftUI
import SwiftData

@main
struct MyClosetApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .modelContainer(
                for: [ClothingItem.self, Outfit.self, Trip.self]
            )
        }
    }
}


