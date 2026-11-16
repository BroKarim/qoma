import AppKit
import Combine
import CryptoKit
import Foundation
import Security
import OSLog

@MainActor
final class AccessCoordinator: ObservableObject {
    static let shared = AccessCoordinator()

    @Published private(set) var state: AccessState = .signedOut
    @Published private(set) var accountID: String?
    @Published private(set) var message: String?
    var onAccountChanged: ((String?) -> Void)?

    private struct Credential: Codable {
        let accountId: String
        let deviceId: String
        let token: String
        let issuedAt: Date?
    }
    private struct PendingLogin: Codable {
        let installationId: String
        let verifier: String
        let state: String
    }
    private struct Snapshot: Codable {
        let account_id: String
        let device_id: String
        let scope: String
        let plan: String?
        let status: String
        let access_until: Date?
        let offline_until: Date?
        let trial_ends_at: Date?
        let issued_at: Date
        let version: Int
    }
    private struct StartResponse: Decodable { let url: URL }
    private struct ExchangeResponse: Decodable { let credential: String; let accountId: String; let deviceId: String }
    private struct EntitlementResponse: Decodable { let snapshot: String }

    private var credential: Credential?
    private var snapshot: Snapshot?
    private var trustedWall: Date?
    private var trustedUptime: TimeInterval?

    private var baseURL: URL {
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["QYUBE_API_URL"], let url = URL(string: value) { return url }
        #endif
        return URL(string: "https://qyube.brokarim.com")!
    }

    private init() {
        credential = SecretStore.load("credential").flatMap { try? JSONDecoder().decode(Credential.self, from: $0) }
        accountID = credential?.accountId
        if let accountID, let data = SecretStore.load("snapshot.\(accountID)") {
            snapshot = try? verify(String(decoding: data, as: UTF8.self), credential: credential)
            trustedWall = snapshot?.issued_at
            state = localState(at: trustedNow())
        }
    }

    func openAccountPurchases(checkout: Bool = false) async {
        do {
            guard let credential else { NSWorkspace.shared.open(baseURL.appending(path: "/auth")); return }
            var request = URLRequest(url: baseURL.appending(path: "/api/me/account-link"))
            request.httpMethod = "POST"
            request.setValue("Bearer \(credential.token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.userAuthenticationRequired) }
            let result = try JSONDecoder().decode(StartResponse.self, from: data)
            guard result.url.host == baseURL.host, result.url.scheme == baseURL.scheme else { throw URLError(.badURL) }
            var destination = URLComponents(url: result.url, resolvingAgainstBaseURL: false)
            if checkout {
                var items = destination?.queryItems ?? []
                items.append(URLQueryItem(name: "checkout", value: "1"))
                destination?.queryItems = items
            }
            guard let destinationURL = destination?.url, NSWorkspace.shared.open(destinationURL) else { throw URLError(.cannotOpenFile) }
        } catch {
            message = "Could not open your account. Check your connection and sign in again if needed."
            let alert = NSAlert()
            alert.messageText = "Could not open Account & purchases"
            alert.informativeText = message ?? "Please try again."
            alert.runModal()
        }
    }

    func canStartSession() -> Bool {
        switch localState(at: trustedNow()) {
        case .trialing, .paid: true
        default: false
        }
    }

    func beginLogin() async {
        do {
            let installationId = try SecretStore.installationID()
            let verifier = try Self.randomToken()
            let state = try Self.randomToken()
            let challenge = Self.base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
            try SecretStore.save(JSONEncoder().encode(PendingLogin(installationId: installationId, verifier: verifier, state: state)), as: "pending-login")
            let response: StartResponse = try await post("/api/native-auth/start", body: [
                "installationId": installationId, "deviceName": Host.current().localizedName ?? "Mac",
                "challenge": challenge, "state": state,
            ])
            NSWorkspace.shared.open(response.url)
            message = "Finish signing in in your browser."
        } catch {
            message = "Could not open sign-in. Check your connection and try again."
        }
    }

    func handleCallback(_ url: URL) async {
        guard url.scheme == "qyube", url.host == "auth", url.path == "/callback",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
              let data = SecretStore.load("pending-login"),
              let pending = try? JSONDecoder().decode(PendingLogin.self, from: data),
              pending.state == state else { return }
        do {
            let result: ExchangeResponse = try await post("/api/native-auth/exchange", body: [
                "code": code, "verifier": pending.verifier, "installationId": pending.installationId,
            ])
            let value = Credential(accountId: result.accountId, deviceId: result.deviceId, token: result.credential, issuedAt: Date())
            try SecretStore.save(JSONEncoder().encode(value), as: "credential")
            SecretStore.delete("pending-login")
            credential = value
            accountID = value.accountId
            onAccountChanged?(value.accountId)
            await refreshAccess()
        } catch {
            message = "Sign-in failed. If two Macs are active, remove one on the website and retry."
        }
    }

    func refreshAccess() async {
        guard var credential else { state = .signedOut; return }
        let logger = Logger(subsystem: "com.dzulkiram.qoma", category: "AccessRefresh")
        var stage = "credential rotation"
        logger.notice("Refresh started; host: \(self.baseURL.host ?? "missing", privacy: .public)")
        var failureMessage = "Could not refresh access. Check your connection and try again."
        do {
            if credential.issuedAt.map({ $0.timeIntervalSinceNow < -60 * 86_400 }) ?? true {
                var rotation = URLRequest(url: baseURL.appending(path: "/api/native-auth/refresh"))
                rotation.httpMethod = "POST"
                rotation.setValue("Bearer \(credential.token)", forHTTPHeaderField: "Authorization")
                let (rotationData, rotationResponse) = try await URLSession.shared.data(for: rotation)
                guard let rotationHTTP = rotationResponse as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                logger.notice("Credential rotation HTTP status: \(rotationHTTP.statusCode)")
                if rotationHTTP.statusCode == 401 {
                    signOut()
                    message = "This Mac was signed out. Sign in again."
                    return
                }
                guard rotationHTTP.statusCode == 200 else { throw URLError(.badServerResponse) }
                let rotated = try JSONDecoder().decode(ExchangeResponse.self, from: rotationData)
                guard rotated.accountId == credential.accountId, rotated.deviceId == credential.deviceId else { throw URLError(.userAuthenticationRequired) }
                credential = Credential(accountId: rotated.accountId, deviceId: rotated.deviceId, token: rotated.credential, issuedAt: Date())
                try SecretStore.save(JSONEncoder().encode(credential), as: "credential")
                self.credential = credential
            }
            stage = "entitlement request"
            var request = URLRequest(url: baseURL.appending(path: "/api/me/entitlement"))
            request.setValue("Bearer \(credential.token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            logger.notice("Entitlement HTTP status: \(http.statusCode)")
            if http.statusCode == 401 {
                signOut()
                message = "This Mac was signed out. Sign in again."
                return
            }
            guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
            failureMessage = "Could not verify the access response. Please contact support."
            stage = "response verification"
            let signed = try JSONDecoder().decode(EntitlementResponse.self, from: data).snapshot
            let value = try verify(signed, credential: credential)
            failureMessage = "Could not save access on this Mac. Please try again."
            stage = "saving snapshot"
            try SecretStore.save(Data(signed.utf8), as: "snapshot.\(credential.accountId)")
            snapshot = value
            trustedWall = value.issued_at
            trustedUptime = ProcessInfo.processInfo.systemUptime
            state = localState(at: Date())
            message = nil
            logger.notice("Refresh succeeded; status: \(value.status, privacy: .public), plan: \(value.plan ?? "none", privacy: .public)")
        } catch {
            let error = error as NSError
            logger.error("Refresh failed at \(stage, privacy: .public); domain: \(error.domain, privacy: .public), code: \(error.code)")
            state = localState(at: trustedNow())
            message = failureMessage
        }
    }

    func signOut() {
        credential = nil
        snapshot = nil
        accountID = nil
        state = .signedOut
        SecretStore.delete("credential")
        onAccountChanged?(nil)
    }

    func signOutRemote() async {
        guard let credential else { return }
        var request = URLRequest(url: baseURL.appending(path: "/api/me/device"))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(credential.token)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            guard http.statusCode == 200 || http.statusCode == 401 else { throw URLError(.badServerResponse) }
            signOut()
            if http.statusCode == 401 {
                message = "This Mac was signed out locally. Check connected Macs on the website if you need to remove it."
            }
        } catch {
            message = "Sign-out needs an internet connection so this Mac can be removed from your account."
        }
    }

    private func localState(at now: Date) -> AccessState {
        guard credential != nil else { return .signedOut }
        guard let snapshot else { return .unknown }
        guard snapshot.status == "active", let offlineUntil = snapshot.offline_until, now < offlineUntil else { return .expired }
        switch snapshot.plan {
        case "trial":
            guard let end = snapshot.trial_ends_at, now < end else { return .expired }
            return .trialing(expiresAt: end)
        case "monthly", "annual", "lifetime": return .paid
        default: return .expired
        }
    }

    private func trustedNow() -> Date {
        let wall = Date()
        guard let trustedWall else { return wall }
        guard let trustedUptime else {
            return wall >= trustedWall.addingTimeInterval(-300) ? wall : .distantFuture
        }
        let elapsed = ProcessInfo.processInfo.systemUptime - trustedUptime
        if elapsed >= 0 { return max(wall, trustedWall.addingTimeInterval(elapsed)) }
        return wall >= trustedWall.addingTimeInterval(-300) ? wall : .distantFuture
    }

    private func verify(_ jws: String, credential: Credential?) throws -> Snapshot {
        let logger = Logger(subsystem: "com.dzulkiram.qoma", category: "AccessRefresh")
        guard let credential,
              let encodedKey = Bundle.main.object(forInfoDictionaryKey: "QyubeEntitlementPublicKey") as? String,
              let keyData = Data(base64Encoded: encodedKey),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
            logger.error("Verification failed: missing credential or invalid public key in app bundle")
            throw URLError(.userAuthenticationRequired)
        }
        let parts = jws.split(separator: ".")
        guard parts.count == 3,
              let headerData = Self.decodeBase64URL(String(parts[0])),
              let body = Self.decodeBase64URL(String(parts[1])),
              let signature = Self.decodeBase64URL(String(parts[2])),
              let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: String],
              header["alg"] == "EdDSA", header["kid"] == "v1" else {
            logger.error("Verification failed: invalid token format or header")
            throw URLError(.userAuthenticationRequired)
        }
        guard key.isValidSignature(signature, for: Data("\(parts[0]).\(parts[1])".utf8)) else {
            logger.error("Verification failed: signature does not match bundled public key")
            throw URLError(.userAuthenticationRequired)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Invalid date")
        }
        let value = try decoder.decode(Snapshot.self, from: body)
        guard value.account_id == credential.accountId, value.device_id == credential.deviceId,
              value.scope == "macos", value.issued_at <= Date().addingTimeInterval(300) else {
            logger.error("Verification failed: account/device, scope or issued time mismatch")
            throw URLError(.userAuthenticationRequired)
        }
        return value
    }

    private func post<T: Decodable>(_ path: String, body: [String: String]) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func randomToken() throws -> String {
        var bytes = Data(count: 32)
        let status = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        guard status == errSecSuccess else { throw URLError(.cannotCreateFile) }
        return base64URL(bytes)
    }
    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    private static func decodeBase64URL(_ value: String) -> Data? {
        let standard = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        return Data(base64Encoded: standard + String(repeating: "=", count: (4 - standard.count % 4) % 4))
    }
}

private enum SecretStore {
    private static let service = "com.dzulkiram.qoma.access"
    private static func query(_ name: String) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: name]
    }
    static func load(_ name: String) -> Data? {
        var result: CFTypeRef?
        var options = query(name)
        options[kSecReturnData] = true
        options[kSecMatchLimit] = kSecMatchLimitOne
        return SecItemCopyMatching(options as CFDictionary, &result) == errSecSuccess ? result as? Data : nil
    }
    static func installationID() throws -> String {
        var result: CFTypeRef?
        var options = query("installation-id")
        options[kSecReturnData] = true
        options[kSecMatchLimit] = kSecMatchLimitOne
        let status = SecItemCopyMatching(options as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data,
           let id = String(data: data, encoding: .utf8) { return id }
        guard status == errSecItemNotFound else { throw URLError(.userAuthenticationRequired) }
        let id = UUID().uuidString
        try save(Data(id.utf8), as: "installation-id")
        return id
    }
    static func save(_ data: Data, as name: String) throws {
        let status = SecItemUpdate(query(name) as CFDictionary, [kSecValueData: data] as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw URLError(.cannotWriteToFile) }
        var options = query(name)
        options[kSecValueData] = data
        options[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(options as CFDictionary, nil) == errSecSuccess else { throw URLError(.cannotWriteToFile) }
    }
    static func delete(_ name: String) { SecItemDelete(query(name) as CFDictionary) }
}
