import Foundation
import UIKit
import AuthenticationServices

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userID: String?

    private static let userIDKey = "appleSignInUserID"

    override init() {
        super.init()
        checkExistingCredential()
    }

    /// Called by the SwiftUI SignInWithAppleButton onCompletion handler.
    func handleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        userID = credential.user
        UserDefaults.standard.set(credential.user, forKey: Self.userIDKey)
        isSignedIn = true
    }

    // MARK: Private

    private func checkExistingCredential() {
        guard let stored = UserDefaults.standard.string(forKey: Self.userIDKey) else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: stored) { [weak self] state, _ in
            DispatchQueue.main.async {
                if state == .authorized {
                    self?.isSignedIn = true
                    self?.userID = stored
                } else {
                    UserDefaults.standard.removeObject(forKey: Self.userIDKey)
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userID = credential.user
                UserDefaults.standard.set(credential.user, forKey: Self.userIDKey)
                isSignedIn = true
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("Sign in with Apple error: \(error.localizedDescription)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // This delegate method is always called on the main thread by the framework.
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
