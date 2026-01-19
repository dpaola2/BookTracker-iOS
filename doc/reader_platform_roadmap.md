# Reader Platform Roadmap

> Current state and implementation plan for Reader (Rails) and Reader iOS (SwiftUI)

---

## Executive Summary

Reader is a book tracking app. The Rails backend serves both a web interface and a JSON API. Reader iOS is a native SwiftUI app that consumes the API.

**Current state:** Basic login and shelves list working. Detail views not yet implemented.

---

## Current State

### Reader (Rails Backend)

**Repository:** BookTracker
**Tech:** Rails 7.0.4, Ruby 3.1.2, SQLite3, Devise

#### Web Features (Complete)
- User authentication (Devise)
- Shelves CRUD
- Books CRUD with ISBN lookup
- Book search (Ransack)
- Pagination (Pagy)

#### API Endpoints

| Endpoint | Method | Status | Description |
|----------|--------|--------|-------------|
| `/api/v1/sessions` | POST | ✅ Done | Login, returns `user_id` + `api_key` |
| `/api/v1/shelves` | GET | ✅ Done | List user's shelves with book counts |
| `/api/v1/shelves/:id` | GET | ❌ **TODO** | Single shelf with its books |
| `/api/v1/books` | GET | ✅ Done | List all user's books |
| `/api/v1/books/:id` | GET | ❌ **TODO** | Single book details |

#### API Controllers

```
app/controllers/api/v1/
├── sessions_controller.rb  ✅
├── books_controller.rb     ✅ (index only)
└── shelves_controller.rb   ✅ (index only)
```

---

### Reader iOS (SwiftUI)

**Repository:** booktracker-ios
**Tech:** SwiftUI, iOS 17+, Swift 5.9+

#### App Structure

```
booktracker-ios/
├── booktracker_iosApp.swift   ✅ Entry point
├── ContentView.swift          ✅ Auth routing
├── Services/
│   ├── KeychainHelper.swift   ✅ Credential storage
│   ├── APIClient.swift        ✅ Network layer
│   └── AuthManager.swift      ✅ Auth state
└── Views/
    ├── LoginView.swift        ✅ Email/password login
    ├── ShelvesListView.swift  ✅ List of shelves
    ├── ShelfDetailView.swift  ❌ **TODO** Books in shelf
    └── BookDetailView.swift   ❌ **TODO** Single book
```

#### Screens

| Screen | Status | Description |
|--------|--------|-------------|
| LoginView | ✅ Done | Email + password form, calls `/api/v1/sessions` |
| ShelvesListView | ✅ Done | Shows shelves with book counts, logout button |
| ShelfDetailView | ❌ **TODO** | Tap shelf → see books in that shelf |
| BookDetailView | ❌ **TODO** | Tap book → see title, author, ISBN, cover, notes |

---

## Implementation Roadmap

### Phase 1: API Endpoints (Reader Rails)

#### Task 1.1: Add `GET /api/v1/shelves/:id`

**File:** `app/controllers/api/v1/shelves_controller.rb`

```ruby
# Add :show to routes
resources :shelves, only: [:index, :show]

# Controller
def show
  shelf = @current_user.shelves.find(params[:id])
  render json: {
    shelf: { id: shelf.id, name: shelf.name },
    books: shelf.books.map { |b|
      { id: b.id, title: b.title, author: b.author, isbn: b.isbn }
    }
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Shelf not found' }, status: 404
end
```

#### Task 1.2: Add `GET /api/v1/books/:id`

**File:** `app/controllers/api/v1/books_controller.rb`

```ruby
# Add :show to routes
resources :books, only: [:index, :show]

# Controller
def show
  book = @current_user.books.find(params[:id])
  render json: {
    book: {
      id: book.id,
      title: book.title,
      author: book.author,
      isbn: book.isbn,
      shelf_id: book.shelf_id,
      shelf_name: book.shelf.name,
      image_url: book.image.attached? ? url_for(book.image) : nil,
      comments: book.comments.to_plain_text
    }
  }
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Book not found' }, status: 404
end
```

---

### Phase 2: iOS Views (Reader iOS)

#### Task 2.1: Add ShelfDetailView

**File:** `Views/ShelfDetailView.swift`

- Navigate from ShelvesListView when tapping a shelf
- Call `GET /api/v1/shelves/:id`
- Display list of books (title, author)
- Tap book → navigate to BookDetailView
- Pull-to-refresh, loading state, error handling

**APIClient addition:**
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

static func getShelf(id: Int) async throws -> ShelfDetailResponse
```

#### Task 2.2: Add BookDetailView

**File:** `Views/BookDetailView.swift`

- Navigate from ShelfDetailView when tapping a book
- Call `GET /api/v1/books/:id`
- Display: title, author, ISBN, shelf name, cover image, comments
- Loading state, error handling

**APIClient addition:**
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

static func getBook(id: Int) async throws -> BookDetailResponse
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Reader iOS                           │
├─────────────────────────────────────────────────────────────┤
│  LoginView ──POST /sessions──▶ Store api_key in Keychain   │
│       │                                                     │
│       ▼                                                     │
│  ShelvesListView ◀──GET /shelves── Fetch on appear         │
│       │                                                     │
│       ▼ (tap shelf)                                         │
│  ShelfDetailView ◀──GET /shelves/:id── Fetch on appear     │
│       │                                                     │
│       ▼ (tap book)                                          │
│  BookDetailView ◀──GET /books/:id── Fetch on appear        │
└─────────────────────────────────────────────────────────────┘

Data loads fresh from API on each screen.
Only auth credentials stored locally (Keychain).
```

---

## Task Checklist

### Reader (Rails)
- [ ] Add `GET /api/v1/shelves/:id` endpoint
- [ ] Add `GET /api/v1/books/:id` endpoint
- [ ] (Optional) Add API documentation page

### Reader iOS
- [ ] Add ShelfDetailView with navigation from ShelvesListView
- [ ] Add BookDetailView with navigation from ShelfDetailView
- [ ] Update APIClient with new response types and methods

---

## API Response Reference

### POST /api/v1/sessions
```json
{ "user_id": 123, "api_key": "abc123..." }
```

### GET /api/v1/shelves
```json
{
  "user": "user@example.com",
  "shelves": [
    { "id": 1, "name": "Currently Reading", "book_count": 3 }
  ]
}
```

### GET /api/v1/shelves/:id (TODO)
```json
{
  "shelf": { "id": 1, "name": "Currently Reading" },
  "books": [
    { "id": 1, "title": "Book Title", "author": "Author", "isbn": "123" }
  ]
}
```

### GET /api/v1/books/:id (TODO)
```json
{
  "book": {
    "id": 1,
    "title": "Book Title",
    "author": "Author Name",
    "isbn": "1234567890",
    "shelf_id": 1,
    "shelf_name": "Currently Reading",
    "image_url": "/rails/active_storage/...",
    "comments": "Plain text notes"
  }
}
```

---

## Notes

- All API requests require `api_key` and `user_id` query params
- iOS app targets iOS 17+ with SwiftUI
- No local data persistence beyond Keychain (auth only)
- Rails serves both web UI and API from same app
