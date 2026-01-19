//
//  LoginView.swift
//  booktracker-ios
//

import SwiftUI

@MainActor
@Observable
class AuthViewModel {
    var email = ""
    var password = ""
    var errorMessage: String?
    var isLoading = false

    func login() async -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await APIClient.login(email: email, password: password)
            isLoading = false
            return true
        } catch APIError.unauthorized {
            errorMessage = "Invalid email or password"
        } catch APIError.serverError(let code) {
            errorMessage = "Server error (\(code))"
        } catch {
            errorMessage = "Connection failed. Please try again."
        }

        isLoading = false
        return false
    }
}

struct LoginView: View {
    @State private var viewModel = AuthViewModel()
    var onLoginSuccess: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Book Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    Task {
                        if await viewModel.login() {
                            onLoginSuccess()
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

#Preview {
    LoginView(onLoginSuccess: {})
}
