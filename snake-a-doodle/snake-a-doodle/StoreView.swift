import SwiftUI

struct StoreView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "nosign")
                        .font(.system(size: 72))
                        .foregroundStyle(.orange)

                    VStack(spacing: 8) {
                        Text("Remove Ads")
                            .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white)
                        Text("One-time purchase — play forever ad-free")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    if storeManager.hasPurchased {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Purchased — Thanks!")
                        }
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.green)
                    } else {
                        VStack(spacing: 14) {
                            Button {
                                Task { await storeManager.purchase() }
                            } label: {
                                if storeManager.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                } else {
                                    Text("Buy for $0.99")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                }
                            }
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .disabled(storeManager.isLoading)
                            .padding(.horizontal, 40)

                            Button("Restore Purchase") {
                                Task { await storeManager.restore() }
                            }
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.gray)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
