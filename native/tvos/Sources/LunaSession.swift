import Foundation
import SwiftUI
import Security

private struct StoredCookie: Codable {
    var name: String; var value: String; var domain: String; var path: String; var secure: Bool; var expires: Date?
    init(_ cookie: HTTPCookie) {
        name = cookie.name; value = cookie.value; domain = cookie.domain; path = cookie.path
        secure = cookie.isSecure; expires = cookie.expiresDate
    }
    var cookie: HTTPCookie? {
        var fields: [HTTPCookiePropertyKey: Any] = [.name: name, .value: value, .domain: domain, .path: path, .secure: secure ? "TRUE" : "FALSE"]
        if let expires { fields[.expires] = expires }
        return HTTPCookie(properties: fields)
    }
}
private enum CookieVault {
    static func query(_ server: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "OrionTVNative.Session", kSecAttrAccount as String: server]
    }
    static func save(_ server: String, cookies: [HTTPCookie]) throws {
        let data = try JSONEncoder().encode(cookies.map(StoredCookie.init))
        var q = query(server); SecItemDelete(q as CFDictionary)
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(q as CFDictionary, nil) == errSecSuccess else { throw NativeError(message: "无法把登录会话保存在钥匙串中。") }
    }
    static func restore(_ server: String) {
        var q = query(server); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        if SecItemCopyMatching(q as CFDictionary, &value) == errSecSuccess, let data = value as? Data,
           let items = try? JSONDecoder().decode([StoredCookie].self, from: data) {
            items.compactMap(\.cookie).filter { $0.expiresDate.map { $0 > Date() } ?? true }.forEach { HTTPCookieStorage.shared.setCookie($0) }
        }
    }
    static func clear(_ server: String) { SecItemDelete(query(server) as CFDictionary) }
}

@MainActor final class LunaSession: ObservableObject {
    @Published var authenticated = false
    @Published var starting = true
    @Published var siteName = "OrionTV"
    @Published var server: String
    @Published var message: String?
    let client: URLSession
    init() {
        server = UserDefaults.standard.string(forKey: "native.server") ?? Bundle.main.object(forInfoDictionaryKey: "OrionServerURL") as? String ?? ""
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared; config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 30; config.timeoutIntervalForResource = 90
        client = URLSession(configuration: config)
    }
    func endpoint(_ path: String, query: [String: String] = [:]) throws -> URL {
        guard var parts = URLComponents(string: server + path), ["http", "https"].contains(parts.scheme?.lowercased() ?? ""), parts.host != nil else {
            throw NativeError(message: "请输入有效的 LunaTV 服务器地址。")
        }
        if !query.isEmpty { parts.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) } }
        guard let url = parts.url else { throw NativeError(message: "服务器地址无效。") }; return url
    }
    func configure(_ address: String) throws {
        let normalized = address.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: normalized), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { throw NativeError(message: "请输入完整的 http:// 或 https:// 地址。") }
        if server != normalized { clearSession() }
        server = normalized; UserDefaults.standard.set(server, forKey: "native.server")
    }
    func request(_ path: String, query: [String: String] = [:], method: String = "GET", body: [String: Any]? = nil) async throws -> Any {
        var request = URLRequest(url: try endpoint(path, query: query)); request.httpMethod = method
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body); request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NativeError(message: "服务器未返回有效响应。") }
        if http.statusCode == 401 { authenticated = false; throw NativeError(message: "登录会话已过期，请重新登录。") }
        guard (200..<300).contains(http.statusCode) else { throw NativeError(message: "服务器返回 HTTP \(http.statusCode)，请检查网络或稍后重试。") }
        guard !data.isEmpty else { return [:] }
        return try JSONSerialization.jsonObject(with: data)
    }
    func bootstrap() async {
        defer { starting = false }
        guard !server.isEmpty else { return }
        CookieVault.restore(server)
        do {
            if let config = try await request("/api/server-config") as? [String: Any] { siteName = config["SiteName"] as? String ?? "OrionTV" }
            _ = try await request("/api/favorites"); authenticated = true
        } catch { message = error.localizedDescription }
    }
    func login(address: String, username: String, password: String) async throws {
        try configure(address)
        let result = try await request("/api/login", method: "POST", body: ["username": username, "password": password]) as? [String: Any]
        guard result?["ok"] as? Bool == true else { throw NativeError(message: "登录失败，请检查用户名和密码。") }
        if let url = URL(string: server) { try CookieVault.save(server, cookies: HTTPCookieStorage.shared.cookies(for: url) ?? []) }
        authenticated = true; message = nil
    }
    func clearSession() {
        CookieVault.clear(server)
        if let url = URL(string: server) { HTTPCookieStorage.shared.cookies(for: url)?.forEach { HTTPCookieStorage.shared.deleteCookie($0) } }
        authenticated = false
    }
    func logout() async { _ = try? await request("/api/logout", method: "POST"); clearSession() }
    func images(_ value: String) -> URL? { try? endpoint("/api/image-proxy", query: ["url": value]) }
    func search(_ query: String, source: String? = nil) async throws -> [Media] {
        var parameters = ["q": query]; if let source { parameters["resourceId"] = source }
        let json = try await request(source == nil ? "/api/search" : "/api/search/one", query: parameters) as? [String: Any]
        return (json?["results"] as? [[String: Any]] ?? []).map { Media($0) }.filter { !$0.title.isEmpty }
    }
    func discover(category: BrowseCategory, tag: String, start: Int) async throws -> [Media] {
        let json = try await request("/api/douban", query: ["type": category.type, "tag": tag, "pageSize": "20", "pageStart": String(start)]) as? [String: Any]
        return (json?["list"] as? [[String: Any]] ?? []).map { Media($0) }
    }
    func library(_ endpoint: String) async throws -> [Media] {
        let json = try await request(endpoint) as? [String: [String: Any]] ?? [:]
        return json.map { Media($0.value, key: $0.key) }.sorted { $0.saved > $1.saved }
    }
    func saveFavorite(_ item: Media) async throws { _ = try await request("/api/favorites", method: "POST", body: ["key": item.id, "favorite": item.favoriteBody]) }
    func removeFavorite(_ item: Media) async throws { _ = try await request("/api/favorites", query: ["key": item.id], method: "DELETE") }
    func saveProgress(_ item: Media, episode: Int, time: Double, duration: Double) async {
        guard !item.source.isEmpty, time.isFinite, duration.isFinite, duration > 0, time > 0 else { return }
        _ = try? await request("/api/playrecords", method: "POST", body: ["key": item.id, "record": item.recordBody(index: episode, time: time, total: duration)])
    }
}
