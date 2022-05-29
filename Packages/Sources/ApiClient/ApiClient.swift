import Foundation

final class ApiClient {
    enum ApiError: Error {
        case invalidUrl
    }

    let baseUrL = "https://jsonplaceholder.typicode.com"

    func fetchTodos() async throws -> [Todo] {
        guard let url = URL(string: baseUrL) else {
            throw ApiError.invalidUrl
        }
        let postsUrl = url.appendingPathComponent("todos")
        let (data, _) = try await URLSession.shared.data(from: postsUrl)

        let posts = try JSONDecoder().decode([Todo].self, from: data)
        return posts
    }

    func fetchUsers() async throws -> [User] {
        guard let url = URL(string: baseUrL) else {
            throw ApiError.invalidUrl
        }
        let postsUrl = url.appendingPathComponent("users")
        let (data, _) = try await URLSession.shared.data(from: postsUrl)

        let users = try JSONDecoder().decode([User].self, from: data)
        return users
    }
}

struct Todo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

struct User: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
}
