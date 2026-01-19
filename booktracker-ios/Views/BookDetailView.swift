//
//  BookDetailView.swift
//  booktracker-ios
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class BookDetailViewModel: ObservableObject {
    @Published var book: BookDetail?
    @Published var isLoading = false
    @Published var error: String?

    let bookId: Int

    init(bookId: Int) {
        self.bookId = bookId
    }

    func loadBook() async {
        isLoading = true
        error = nil

        do {
            let response = try await APIClient.getBook(id: bookId)
            book = response.book
        } catch let apiError as APIError {
            switch apiError {
            case .unauthorized:
                error = "Session expired. Please log in again."
            case .serverError(let code):
                error = "Server error (\(code)). Please try again."
            default:
                error = "Failed to load book details. Please try again."
            }
        } catch {
            self.error = "An unexpected error occurred."
        }

        isLoading = false
    }
}

// MARK: - View

struct BookDetailView: View {
    @StateObject private var viewModel: BookDetailViewModel

    init(bookId: Int) {
        _viewModel = StateObject(wrappedValue: BookDetailViewModel(bookId: bookId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.book == nil {
                ProgressView("Loading book...")
            } else if let error = viewModel.error, viewModel.book == nil {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await viewModel.loadBook()
                        }
                    }
                }
            } else if let book = viewModel.book {
                BookContentView(book: book)
            }
        }
        .navigationTitle(viewModel.book?.title ?? "Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBook()
        }
    }
}

// MARK: - Book Content View

struct BookContentView: View {
    let book: BookDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 300)
                        case .failure:
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)

                    if let author = book.author {
                        Label(author, systemImage: "person")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    if let isbn = book.isbn {
                        LabeledContent("ISBN", value: isbn)
                    }

                    LabeledContent("Shelf", value: book.shelfName)

                    if let comments = book.comments, !comments.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(comments)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    NavigationStack {
        BookDetailView(bookId: 1)
    }
}
