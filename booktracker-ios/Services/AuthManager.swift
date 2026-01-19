//
//  AuthManager.swift
//  booktracker-ios
//

import Foundation

@MainActor
@Observable
class AuthManager {
    var isAuthenticated: Bool

    init() {
        isAuthenticated = KeychainHelper.get(key: "api_key") != nil
    }

    func login() {
        isAuthenticated = true
    }

    func logout() {
        APIClient.logout()
        isAuthenticated = false
    }
}
