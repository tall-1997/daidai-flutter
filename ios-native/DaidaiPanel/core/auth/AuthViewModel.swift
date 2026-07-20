import Foundation
import Combine

enum AuthStatus {
    case unknown
    case unauthenticated
    case authenticated
}

struct AuthState {
    var status: AuthStatus = .unknown
    var user: User?
    var needsInit: Bool = false
    var error: String?
}

@MainActor
final class AuthViewModel: ObservableObject, AuthInterceptorDelegate {
    @Published var state = AuthState()

    private let authService: AuthService
    private let keychain: KeychainStorage
    private var hasRestored = false

    init(api: ApiService, keychain: KeychainStorage) {
        self.authService = AuthService(api: api, keychain: keychain)
        self.keychain = keychain
        api.authInterceptor.delegate = self
    }

    var isAuthenticated: Bool { state.status == .authenticated }
    var isLoading: Bool { state.status == .unknown }

    func restoreTrustedLocalSession() async {
        guard !hasRestored else { return }
        hasRestored = true

        guard keychain.isTrustedLoginValid,
              let serverURL = keychain.trustedLoginServerURLValue else {
            await checkAuthStatus()
            return
        }

        keychain.serverURL = serverURL.absoluteString
        await restoreSession()
    }

    func restoreSession() async {
        guard keychain.isAuthenticated else {
            state = AuthState(status: .unauthenticated)
            return
        }

        do {
            let user = try await authService.getUser()
            state = AuthState(status: .authenticated, user: user)
        } catch {
            // Fallback: try to restore user from local cache
            if let cachedUser = keychain.authUser {
                state = AuthState(status: .authenticated, user: cachedUser)
                return
            }
            do {
                try await authService.refreshToken()
                let user = try await authService.getUser()
                state = AuthState(status: .authenticated, user: user)
            } catch {
                keychain.clearAuth()
                state = AuthState(status: .unauthenticated, error: error.localizedDescription)
            }
        }
    }

    func checkAuthStatus() async {
        do {
            let initialized = try await authService.checkInit()
            if initialized {
                if keychain.isAuthenticated {
                    await restoreSession()
                } else {
                    state = AuthState(status: .unauthenticated, needsInit: false)
                }
            } else {
                state = AuthState(status: .unauthenticated, needsInit: true)
            }
        } catch {
            state = AuthState(status: .unauthenticated, error: error.localizedDescription)
        }
    }

    func login(username: String, password: String, captcha: String? = nil) async throws {
        let user = try await authService.login(username: username, password: password, captcha: captcha)
        state = AuthState(status: .authenticated, user: user)
    }

    func initAdmin(username: String, password: String) async throws {
        try await authService.initAdmin(username: username, password: password)
        try await login(username: username, password: password)
    }

    func logout() async {
        await authService.logout()
        keychain.clearAuth()
        state = AuthState(status: .unauthenticated)
    }

    func refreshUser() async {
        do {
            let user = try await authService.getUser()
            state.user = user
        } catch {}
    }

    // MARK: - AuthInterceptorDelegate

    nonisolated func authInterceptorDidFailAuth(_ interceptor: AuthInterceptor) {
        Task { @MainActor in
            keychain.clearAuth()
            state = AuthState(status: .unauthenticated, error: "认证已过期，请重新登录")
        }
    }
}
