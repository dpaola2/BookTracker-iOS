# Reader iOS - Software Design Document

> Current architecture as of January 2026

---

## System Overview

Reader iOS is a native SwiftUI application targeting iOS 17+. It communicates with the Reader Rails backend via JSON API. No third-party dependencies are used.

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| Language | Swift 5.9+ |
| Minimum iOS | 17.0 |
| Networking | URLSession |
| Storage | Keychain (credentials only) |
| State Management | @Observable, @StateObject |
| Concurrency | async/await |

---

## Architecture

### Directory Structure

```
booktracker-ios/
├── booktracker_iosApp.swift    # Entry point, AuthManager init
├── ContentView.swift            # Auth-based routing
├── Services/
│   ├── APIClient.swift         # Network layer + data models
│   ├── AuthManager.swift       # Auth state (@Observable)
│   └── KeychainHelper.swift    # Secure credential storage
└── Views/
    ├── LoginView.swift         # Login form + AuthViewModel
    ├── ShelvesListView.swift   # Shelves list + ShelvesViewModel
    ├── ShelfDetailView.swift   # Books in shelf + ShelfDetailViewModel
    └── BookDetailView.swift    # Single book + BookDetailViewModel
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    booktracker_iosApp                    │
│                         │                                │
│              ┌──────────┴──────────┐                    │
│              ▼                     │                    │
│        AuthManager ◀───────────────┤                    │
│         (@Observable)              │                    │
│              │                     │                    │
└──────────────┼─────────────────────┼────────────────────┘
               │                     │
               ▼                     ▼
        ┌─────────────┐      ┌──────────────┐
        │ ContentView │      │ Environment  │
        └─────────────┘      └──────────────┘
               │
      ┌────────┴────────┐
      ▼                 ▼
┌───────────┐    ┌────────────────┐
│ LoginView │    │ ShelvesListView│
└───────────┘    └────────────────┘
                         │
                         ▼
                 ┌────────────────┐
                 │ ShelfDetailView│
                 └────────────────┘
                         │
                         ▼
                 ┌────────────────┐
                 │ BookDetailView │
                 └────────────────┘

All views use ViewModels → APIClient → KeychainHelper
```

---

## Data Models

All models defined in `APIClient.swift`:

### AuthResponse

```swift
struct AuthResponse: Codable {
    let userId: Int
    let apiKey: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case apiKey = "api_key"
    }
}
```

### ShelvesResponse

```swift
struct ShelvesResponse: Codable {
    let user: String
    let shelves: [Shelf]
}
```

### Shelf

```swift
struct Shelf: Codable, Identifiable {
    let id: Int
    let name: String
    let bookCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case bookCount = "book_count"
    }
}
```

### ShelfDetailResponse

```swift
struct ShelfDetailResponse: Codable {
    let shelf: ShelfInfo
    let books: [BookSummary]
}

struct ShelfInfo: Codable {
    let id: Int
    let name: String
}

struct BookSummary: Codable {
    let id: Int
    let title: String
    let author: String?
    let isbn: String?
}
```

### BookDetailResponse

```swift
struct BookDetailResponse: Codable {
    let book: BookDetail
}

struct BookDetail: Codable {
    let id: Int
    let title: String
    let author: String?
    let isbn: String?
    let shelfId: Int
    let shelfName: String
    let imageUrl: String?
    let comments: String?

    enum CodingKeys: String, CodingKey {
        case id, title, author, isbn, comments
        case shelfId = "shelf_id"
        case shelfName = "shelf_name"
        case imageUrl = "image_url"
    }
}
```

---

## Services

### KeychainHelper

Secure credential storage using iOS Keychain.

```swift
class KeychainHelper {
    static let shared = KeychainHelper()

    func save(key: String, value: String)  // Store credential
    func get(key: String) -> String?       // Retrieve credential
    func delete(key: String)               // Remove credential
}
```

**Stored Keys:**
- `api_key` - API authentication key
- `user_id` - User identifier

### AuthManager

Observable authentication state manager.

```swift
@Observable
class AuthManager {
    var isAuthenticated: Bool

    func login()   // Set authenticated (after API success)
    func logout()  // Clear Keychain, set unauthenticated
}
```

### APIClient

Static network client for API communication.

```swift
struct APIClient {
    static var baseURL = "http://localhost:3000"

    // Authentication
    static func login(email: String, password: String) async throws -> AuthResponse
    static func logout()  // Clears Keychain

    // Shelves
    static func getShelves() async throws -> ShelvesResponse
    static func getShelf(id: Int) async throws -> ShelfDetailResponse

    // Books
    static func getBook(id: Int) async throws -> BookDetailResponse
}
```

**Error Handling:**

```swift
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized           // 401 response
    case serverError(Int)       // Other HTTP errors
    case decodingError(Error)   // JSON parsing failure
}
```

---

## View Architecture

### LoginView

- **State**: `@State` for form fields, `@StateObject` for AuthViewModel
- **ViewModel**: Handles login API call, error state, loading state
- **Callbacks**: `onLoginSuccess` closure to notify parent

```swift
struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    var onLoginSuccess: () -> Void

    var body: some View {
        // Email field, password field, login button, error display
    }
}
```

### ShelvesListView

- **State**: `@StateObject` for ShelvesViewModel
- **Features**: Pull-to-refresh, loading/error states
- **Navigation**: NavigationStack with NavigationLink to ShelfDetailView

```swift
struct ShelvesListView: View {
    @StateObject private var viewModel = ShelvesViewModel()
    var onLogout: () -> Void

    var body: some View {
        NavigationStack {
            List(viewModel.shelves) { shelf in
                NavigationLink(value: shelf) {
                    // Shelf row with name and book count
                }
            }
            .navigationDestination(for: Shelf.self) { shelf in
                ShelfDetailView(shelf: shelf, onLogout: onLogout)
            }
        }
        .task { await viewModel.loadShelves() }
        .refreshable { await viewModel.loadShelves() }
    }
}
```

### ShelfDetailView

- **State**: `@StateObject` for ShelfDetailViewModel
- **Input**: Shelf object (id, name)
- **Features**: Loading/error states, NavigationLink to BookDetailView

```swift
struct ShelfDetailView: View {
    let shelf: Shelf
    @StateObject private var viewModel = ShelfDetailViewModel()
    var onLogout: () -> Void

    var body: some View {
        List(viewModel.books) { book in
            NavigationLink(value: book) {
                // Book row with title and author
            }
        }
        .navigationTitle(shelf.name)
        .navigationDestination(for: BookSummary.self) { book in
            BookDetailView(bookId: book.id, onLogout: onLogout)
        }
        .task { await viewModel.loadShelf(id: shelf.id) }
    }
}
```

### BookDetailView

- **State**: `@StateObject` for BookDetailViewModel
- **Input**: Book ID
- **Features**: Loading/error states, displays full book details with cover image

```swift
struct BookDetailView: View {
    let bookId: Int
    @StateObject private var viewModel = BookDetailViewModel()
    var onLogout: () -> Void

    var body: some View {
        ScrollView {
            // Cover image (AsyncImage if imageUrl present)
            // Title, author, ISBN
            // Shelf name
            // Comments/notes
        }
        .task { await viewModel.loadBook(id: bookId) }
    }
}
```

### ContentView

- **Routing**: Switches between LoginView and ShelvesListView based on auth state
- **Environment**: Reads AuthManager from environment

```swift
struct ContentView: View {
    @Environment(AuthManager.self) var authManager

    var body: some View {
        if authManager.isAuthenticated {
            ShelvesListView(onLogout: { authManager.logout() })
        } else {
            LoginView(onLoginSuccess: { authManager.login() })
        }
    }
}
```

---

## API Integration

### Authentication Flow

```
1. User submits email/password
2. APIClient.login() sends POST /api/v1/sessions
3. Server returns { user_id, api_key }
4. KeychainHelper stores both values
5. AuthManager.login() sets isAuthenticated = true
6. ContentView routes to ShelvesListView
```

### Authenticated Requests

```
1. APIClient reads credentials from KeychainHelper
2. Appends ?api_key=...&user_id=... to URL
3. Server validates credentials
4. Returns data or 401 error
```

### Error Handling

| Scenario | Response |
|----------|----------|
| Invalid credentials | Show error on LoginView |
| 401 on shelves fetch | Auto-logout, show LoginView |
| Network error | Show error with retry button |
| Decoding error | Show generic error message |

---

## State Management Patterns

### @Observable (iOS 17+)

Used for `AuthManager` - global authentication state shared via Environment.

```swift
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
```

### @StateObject

Used for view-specific ViewModels that survive view recreation.

```swift
struct ShelvesListView: View {
    @StateObject private var viewModel = ShelvesViewModel()
}
```

### @MainActor

Used on ViewModels to ensure UI updates happen on main thread.

```swift
@MainActor
class ShelvesViewModel: ObservableObject {
    @Published var shelves: [Shelf] = []
    @Published var isLoading = false
    @Published var error: String?
}
```

---

## Security

### Keychain Storage

- Credentials never stored in UserDefaults or files
- Keychain provides OS-level encryption
- Service identifier: app bundle ID

### Network Security

- All API calls should use HTTPS in production
- Currently configured for localhost (development)
- No certificate pinning implemented

---

## Key Design Decisions

1. **No Third-Party Dependencies**: Pure SwiftUI + Foundation
2. **Online-Only**: No local data cache, always fetch fresh
3. **Minimal Scope**: Read-only access to shelves (no mutations)
4. **iOS 17+**: Enables modern @Observable pattern
5. **ViewModels per Screen**: Each view has its own ViewModel
6. **Callback-Based Navigation**: Parent controls routing via closures
