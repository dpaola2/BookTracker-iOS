//
//  BookDetailView.swift
//  booktracker-ios
//

import SwiftUI
import Combine
import WebKit

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
        print("📚 BookDetailViewModel: Loading book \(bookId)")

        do {
            let response = try await APIClient.getBook(id: bookId)
            print("📚 BookDetailViewModel: Got response for book \(bookId)")
            book = response.book
        } catch let apiError as APIError {
            print("📚 BookDetailViewModel: API error: \(apiError)")
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
    @State private var commentsHeight: CGFloat = 100

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
                            HTMLTextView(html: comments, dynamicHeight: $commentsHeight)
                                .frame(height: commentsHeight)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - HTML Text View

struct HTMLTextView: UIViewRepresentable {
    let html: String
    @Binding var dynamicHeight: CGFloat

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let wrappedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    color: \(UIColor.label.hexString);
                    background-color: transparent;
                    -webkit-text-size-adjust: 100%;
                }
                p { margin-bottom: 12px; }
                p:last-child { margin-bottom: 0; }
                a { color: \(UIColor.tintColor.hexString); }
                strong, b { font-weight: 600; }
                ul, ol { padding-left: 20px; margin-bottom: 12px; }
                li { margin-bottom: 4px; }
            </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(wrappedHTML, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLTextView

        init(_ parent: HTMLTextView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.dynamicHeight = height
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

// MARK: - UIColor Extension

private extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}

#Preview {
    NavigationStack {
        BookDetailView(bookId: 1)
    }
}
