import Foundation

struct AuthUser: Sendable {
    let uid: String
    let email: String?
    let displayName: String?
}

protocol AuthServiceProtocol: Sendable {
    var currentUser: AuthUser? { get }
    var isAuthenticated: Bool { get }

    func signInWithApple() async throws -> AuthUser
    func signInWithEmail(email: String, password: String) async throws -> AuthUser
    func signUpWithEmail(email: String, password: String) async throws -> AuthUser
    func signInWithGoogle() async throws -> AuthUser
    func signOut() throws
    func deleteAccount() async throws
    func sendEmailVerification() async throws
}
