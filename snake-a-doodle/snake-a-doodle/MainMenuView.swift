import SwiftUI
import SwiftData
import AuthenticationServices

struct MainMenuView: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var authManager: AuthManager
    @Query(sort: \HighScore.score, order: .reverse) private var highScores: [HighScore]

    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showStore = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 6) {
                    Text("SNAKE")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(.green)
                    Text("A-DOODLE")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                Spacer().frame(height: 20)

                if let best = highScores.first {
                    Text("Best: \(best.score)")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.yellow)
                }

                Spacer()

                // Menu buttons
                VStack(spacing: 14) {
                    MenuButton("▶  PLAY", color: .green)   { showGame = true }
                    MenuButton("🏆  SCORES", color: .blue)  { showLeaderboard = true }
                    if !storeManager.hasPurchased {
                        MenuButton("✕  REMOVE ADS  $0.99", color: .orange) { showStore = true }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Sign in with Apple (shown until signed in)
                if !authManager.isSignedIn {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            if case .success(let auth) = result,
                               let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                authManager.handleCredential(credential)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                }

                // Ad banner for non-paying users
                if !storeManager.hasPurchased {
                    AdBannerView()
                }
            }
            .padding(.vertical, 32)
        }
        .fullScreenCover(isPresented: $showGame) {
            GameRootView()
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .sheet(isPresented: $showStore) {
            StoreView()
        }
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    init(_ title: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Ad Banner Placeholder
// Replace with Google AdMob GADBannerView once the SDK is added via SPM.
// SPM URL: https://github.com/googleads/swift-package-manager-google-mobile-ads

struct AdBannerView: View {
    var body: some View {
        Rectangle()
            .fill(Color(white: 0.12))
            .frame(height: 50)
            .overlay {
                Text("ADVERTISEMENT")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.gray.opacity(0.5))
            }
    }
}
