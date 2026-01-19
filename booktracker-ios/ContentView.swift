//
//  ContentView.swift
//  booktracker-ios
//
//  Created by Dave Paola on 1/19/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        if authManager.isAuthenticated {
            ShelvesListView(onLogout: {
                authManager.logout()
            })
        } else {
            LoginView(onLoginSuccess: {
                authManager.login()
            })
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
