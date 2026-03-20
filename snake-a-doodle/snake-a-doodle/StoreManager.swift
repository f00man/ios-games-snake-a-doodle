import StoreKit
import Foundation

@MainActor
class StoreManager: ObservableObject {
    // Product ID must match what is configured in App Store Connect
    static let removeAdsProductID = "MichaelBilberry.snake-a-doodle.removeads"

    @Published var hasPurchased: Bool = false
    @Published var isLoading: Bool = false

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await checkPurchaseStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func purchase() async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let product = try await Product.products(for: [Self.removeAdsProductID]).first else { return }
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(_) = verification {
                hasPurchased = true
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await checkPurchaseStatus()
    }

    // MARK: Private

    private func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.removeAdsProductID {
                hasPurchased = true
                return
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        // Capture the product ID before entering the detached (nonisolated) task,
        // since Self.removeAdsProductID is @MainActor-isolated.
        let productID = Self.removeAdsProductID
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let tx) = result, tx.productID == productID {
                    await MainActor.run { self.hasPurchased = true }
                    await tx.finish()
                }
            }
        }
    }
}
