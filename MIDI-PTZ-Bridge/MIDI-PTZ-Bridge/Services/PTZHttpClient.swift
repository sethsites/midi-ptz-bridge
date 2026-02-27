import os
import Foundation

struct PTZHttpClient {
    
    struct Response {
        let httpResponse: HTTPURLResponse
        let data: Data
    }

    static func buildURL(camera: Camera, path: String) throws -> URL {
        var components = URLComponents()
        components.scheme = camera.scheme.rawValue
        components.host = camera.host
        components.port = camera.port
        if let username = camera.username, let password = camera.password, !username.isEmpty, !password.isEmpty {
            components.user = username
            components.password = password
        }

        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        if let queryStart = normalizedPath.firstIndex(of: "?") {
            components.path = String(normalizedPath[..<queryStart])
            components.query = String(normalizedPath[normalizedPath.index(after: queryStart)...])
        } else {
            components.path = normalizedPath
        }

        guard let url = components.url else {
            throw PTZHttpClientError.invalidURL
        }

        return url
    }

    func buildRequest(camera: Camera, command: CommandTemplate) throws -> URLRequest {
        let requestInfo = PTZOpticsActionCatalog.request(for: command.action, params: command.params)
        let url = try Self.buildURL(camera: camera, path: requestInfo.path)

        var request = URLRequest(url: url)
        request.httpMethod = requestInfo.method

        return request
    }

    func send(camera: Camera, command: CommandTemplate, retries: Int = 3, session: URLSession = .shared) async throws -> Response {
        let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "PTZ", category: "PTZHttpClient")
        let request = try buildRequest(camera: camera, command: command)
        logger.debug("Sending request to: \(request.url?.absoluteString ?? "nil") (retries: \(retries))")
        var lastError: Error?

        for attempt in 0..<max(1, retries) {
            do {
                logger.debug("Attempt #\(attempt + 1) for URL: \(request.url?.absoluteString ?? "nil")")
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    logger.error("Invalid response type for URL: \(request.url?.absoluteString ?? "nil")")
                    throw PTZHttpClientError.invalidResponse
                }
                logger.debug("Received HTTP \(httpResponse.statusCode) from: \(request.url?.absoluteString ?? "nil")")
                return Response(httpResponse: httpResponse, data: data)
            } catch {
                logger.error("Request failed on attempt #\(attempt + 1): \(String(describing: error))")
                lastError = error
                if attempt < retries - 1 {
                    logger.debug("Retrying after delay...")
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
