import Foundation

struct PTZHttpClient {
    struct Response {
        let httpResponse: HTTPURLResponse
        let data: Data
    }

    func buildRequest(camera: Camera, command: CommandTemplate) throws -> URLRequest {
        let path = command.path.hasPrefix("/") ? command.path : "/" + command.path
        guard let url = URL(string: "http://\(camera.ip)\(path)") else {
            throw PTZHttpClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = command.method.rawValue
        if let body = command.body {
            request.httpBody = body.data(using: .utf8)
        }

        for (key, value) in command.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let credentials = "\(camera.username):\(camera.password)"
        if let encoded = credentials.data(using: .utf8)?.base64EncodedString() {
            request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func send(camera: Camera, command: CommandTemplate, retries: Int = 3, session: URLSession = .shared) async throws -> Response {
        let request = try buildRequest(camera: camera, command: command)
        var lastError: Error?

        for attempt in 0..<max(1, retries) {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw PTZHttpClientError.invalidResponse
                }
                return Response(httpResponse: httpResponse, data: data)
            } catch {
                lastError = error
                if attempt < retries - 1 {
                    try await Task.sleep(nanoseconds: 250_000_000)
                }
            }
        }

        throw lastError ?? PTZHttpClientError.requestFailed
    }
}

enum PTZHttpClientError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed
}
