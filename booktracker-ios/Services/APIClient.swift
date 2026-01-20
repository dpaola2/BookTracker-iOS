//
//  APIClient.swift
//  booktracker-ios
//

import Foundation

// MARK: - Models

struct AuthResponse: Codable {
    let userId: Int
    let apiKey: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case apiKey = "api_key"
    }
}

struct ShelvesResponse: Codable {
    let user: String  // API returns email as string
    let shelves: [Shelf]
}

struct Shelf: Codable {
    let id: Int
    let name: String
    let bookCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bookCount = "book_count"
    }
}

struct BookDetailResponse: Codable {
    let book: BookDetail
}

struct ShelfDetailResponse: Codable {
    let shelf: ShelfInfo
    let books: [BookSummary]?
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

// MARK: - API Errors

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
}

// MARK: - APIClient

struct APIClient {

    static var baseURL = "http://localhost:3000"

    // MARK: - Authentication

    static func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/sessions") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            KeychainHelper.save(key: "api_key", value: authResponse.apiKey)
            KeychainHelper.save(key: "user_id", value: String(authResponse.userId))
            return authResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Shelves

    static func getShelves() async throws -> ShelvesResponse {
        guard let apiKey = KeychainHelper.get(key: "api_key"),
              let userId = KeychainHelper.get(key: "user_id") else {
            throw APIError.unauthorized
        }

        guard let url = URL(string: "\(baseURL)/api/v1/shelves?api_key=\(apiKey)&user_id=\(userId)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(ShelvesResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Shelf Detail

    static func getShelf(id: Int) async throws -> ShelfDetailResponse {
        guard let apiKey = KeychainHelper.get(key: "api_key"),
              let userId = KeychainHelper.get(key: "user_id") else {
            throw APIError.unauthorized
        }

        guard let url = URL(string: "\(baseURL)/api/v1/shelves/\(id)?api_key=\(apiKey)&user_id=\(userId)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(ShelfDetailResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Books

    static func getBook(id: Int) async throws -> BookDetailResponse {
        guard let apiKey = KeychainHelper.get(key: "api_key"),
              let userId = KeychainHelper.get(key: "user_id") else {
            throw APIError.unauthorized
        }

        guard let url = URL(string: "\(baseURL)/api/v1/books/\(id)?api_key=\(apiKey)&user_id=\(userId)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(BookDetailResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Logout

    static func logout() {
        KeychainHelper.delete(key: "api_key")
        KeychainHelper.delete(key: "user_id")
    }
}
