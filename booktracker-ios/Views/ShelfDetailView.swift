//
//  ShelfDetailView.swift
//  booktracker-ios
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class ShelfDetailViewModel: ObservableObject {
    @Published var shelfName: String
    @Published var books: [BookSummary] = []
    @Published var isLoading = false
    @Published var error: String?

    let shelfId: Int

    init(shelfId: Int, shelfName: String) {
        self.shelfId = shelfId
        self.shelfName = shelfName
    }

    func loadBooks() async {
        isLoading = true
        error = nil

        do {
            let response = try await APIClient.getShelf(id: shelfId)
            shelfName = response.shelf.name
            books = response.shelf.books
        } catch let apiError as APIError {
            switch apiError {
            case .unauthorized:
                error = "Session expired. Please log in again."
            case .serverError(let code):
                error = "Server error (\(code)). Please try again."
            default:
                error = "Failed to load books. Please try again."
            }
        } catch {
            self.error = "An unexpected error occurred."
        }

        isLoading = false
    }
}

// MARK: - View

struct ShelfDetailView: View {
    @StateObject private var viewModel: ShelfDetailViewModel

    init(shelfId: Int, shelfName: String) {
        _viewModel = StateObject(wrappedValue: ShelfDetailViewModel(shelfId: shelfId, shelfName: shelfName))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.books.isEmpty {
                ProgressView("Loading books...")
            } else if let error = viewModel.error, viewModel.books.isEmpty {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await viewModel.loadBooks()
                        }
                    }
                }
            } else if viewModel.books.isEmpty {
                ContentUnavailableView {
                    Label("No Books", systemImage: "book.closed")
                } description: {
                    Text("This shelf doesn't have any books yet.")
                }
            } else {
                List(viewModel.books, id: \.id) { book in
                    NavigationLink(destination: BookDetailView(bookId: book.id)) {
                        BookRow(book: book)
                    }
                }
                .refreshable {
                    await viewModel.loadBooks()
                }
            }
        }
        .navigationTitle(viewModel.shelfName)
        .task {
            await viewModel.loadBooks()
        }
    }
}

// MARK: - Book Row

struct BookRow: View {
    let book: BookSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.headline)
            if let author = book.author {
                Text(author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShelfDetailView(shelfId: 1, shelfName: "Reading")
    }
}
