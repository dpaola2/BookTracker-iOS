# Reader iOS - Screen & API Mapping

## Overview

This document tracks each iOS screen, its web equivalent in the Reader Rails app, and the API endpoint status.

## Screen Mapping

| iOS Screen | Reader Web Analog | API Endpoint | Status |
|------------|-------------------|--------------|--------|
| LoginView | Devise sessions | `POST /api/v1/sessions` | ✅ Exists |
| ShelvesListView | Shelves#index | `GET /api/v1/shelves` | ✅ Exists |
| ShelfDetailView | Shelves#show | `GET /api/v1/shelves/:id` | ❌ **Needed** |
| BookDetailView | Books#show | `GET /api/v1/books/:id` | ❌ **Needed** |

## API Endpoints

### Existing

#### POST /api/v1/sessions
Login with email/password, returns credentials.
```json
// Request
{ "email": "user@example.com", "password": "secret" }

// Response
{ "user_id": 123, "api_key": "abc123..." }
```

#### GET /api/v1/shelves
List all user's shelves.
```json
// Response
{
  "user": "user@example.com",
  "shelves": [
    { "id": 1, "name": "Currently Reading", "book_count": 3 }
  ]
}
```

#### GET /api/v1/books
List all user's books (used for search).
```json
// Response
{
  "user": "user@example.com",
  "books": [...],
  "book_count": 47
}
```

### Needed

#### GET /api/v1/shelves/:id
Get shelf details with books.
```json
// Response
{
  "shelf": {
    "id": 1,
    "name": "Currently Reading"
  },
  "books": [
    { "id": 1, "title": "Book Title", "author": "Author Name", "isbn": "123..." }
  ]
}
```

#### GET /api/v1/books/:id
Get single book details.
```json
// Response
{
  "book": {
    "id": 1,
    "title": "Book Title",
    "author": "Author Name",
    "isbn": "1234567890",
    "shelf_id": 1,
    "shelf_name": "Currently Reading",
    "image_url": "/path/to/cover.jpg",
    "comments": "Rich text comments..."
  }
}
```

## iOS Views

| View | File | Data Source |
|------|------|-------------|
| LoginView | Views/LoginView.swift | Local form → API |
| ShelvesListView | Views/ShelvesListView.swift | API (no local cache) |
| ShelfDetailView | Views/ShelfDetailView.swift | API (no local cache) |
| BookDetailView | Views/BookDetailView.swift | API (no local cache) |

## Data Flow Principle

All data loads in realtime from the API. No local persistence beyond auth credentials in Keychain.
