//
//  ShelvesListView.swift
//  booktracker-ios
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class ShelvesViewModel: ObservableObject {
    @Published var shelves: [Shelf] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadShelves() async {
        isLoading = true
        error = nil

        do {
            let response = try await APIClient.getShelves()
            shelves = response.shelves
        } catch let apiError as APIError {
            switch apiError {
            case .unauthorized:
                error = "Session expired. Please log in again."
            case .serverError(let code):
                error = "Server error (\(code)). Please try again."
            default:
                error = "Failed to load shelves. Please try again."
            }
        } catch {
            self.error = "An unexpected error occurred."
        }

        isLoading = false
    }

    func logout() {
        APIClient.logout()
    }
}

// MARK: - View

struct ShelvesListView: View {
    @StateObject private var viewModel = ShelvesViewModel()
    var onLogout: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.shelves.isEmpty {
                    ProgressView("Loading shelves...")
                } else if let error = viewModel.error, viewModel.shelves.isEmpty {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again") {
                            Task {
                                await viewModel.loadShelves()
                            }
                        }
                    }
                } else if viewModel.shelves.isEmpty {
                    ContentUnavailableView {
                        Label("No Shelves", systemImage: "books.vertical")
                    } description: {
                        Text("You don't have any shelves yet.")
                    }
                } else {
                    List(viewModel.shelves, id: \.id) { shelf in
                        ShelfRow(shelf: shelf)
                    }
                    .refreshable {
                        await viewModel.loadShelves()
                    }
                }
            }
            .navigationTitle("Shelves")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        viewModel.logout()
                        onLogout()
                    }
                }
            }
        }
        .task {
            await viewModel.loadShelves()
        }
    }
}

// MARK: - Shelf Row

struct ShelfRow: View {
    let shelf: Shelf

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(shelf.name)
                    .font(.headline)
                Text("\(shelf.bookCount) \(shelf.bookCount == 1 ? "book" : "books")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ShelvesListView(onLogout: {})
}
