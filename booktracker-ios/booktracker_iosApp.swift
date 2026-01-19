//
//  booktracker_iosApp.swift
//  booktracker-ios
//
//  Created by Dave Paola on 1/19/26.
//

import SwiftUI

@main
struct booktracker_iosApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}
