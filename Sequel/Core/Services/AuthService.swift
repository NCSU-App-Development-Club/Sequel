import Foundation

final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    static let shared = AuthService()

    private(set) var currentUser: AuthUser? = nil
    var isAuthenticated: Bool { currentUser != nil }

    func signInWithApple() async throws -> AuthUser {
        // TODO: Implement Sign in with Apple via Firebase Auth
        throw AppError.authError("Sign in with Apple not yet configured")
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthUser {
        // TODO: Implement email/password sign in via Firebase Auth
        throw AppError.authError("Email sign in not yet configured")
    }

    func signUpWithEmail(email: String, password: String) async throws -> AuthUser {
        // TODO: Implement email/password registration via Firebase Auth
        throw AppError.authError("Email sign up not yet configured")
    }

    func signInWithGoogle() async throws -> AuthUser {
        // TODO: Implement Google Sign-In via Firebase Auth
        throw AppError.authError("Google sign in not yet configured")
    }

    func signOut() throws {
        // TODO: Sign out via Firebase Auth
        currentUser = nil
    }

    func deleteAccount() async throws {
        // TODO: Delete account via Firebase Auth + Cloud Function for data cleanup
        throw AppError.authError("Account deletion not yet configured")
    }

    func sendEmailVerification() async throws {
        // TODO: Send verification email via Firebase Auth
        throw AppError.authError("Email verification not yet configured")
    }
}
