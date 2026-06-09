import SwiftUI

@main
struct SoledexApp: App {
    @StateObject private var store = Store()
    @StateObject private var pro = ProStore()
    private var testPro: Bool { ProcessInfo.processInfo.arguments.contains("-pro") }

    var body: some Scene {
        WindowGroup {
            Group {
                if store.onboarded || ProcessInfo.processInfo.arguments.contains("-skipOnboard") { RootView() }
                else { OnboardingView() }
            }
            .environmentObject(store)
            .environmentObject(pro)
            .tint(Theme.accent)
            .preferredColorScheme(.light)
            .task {
                await pro.load(); store.isPro = pro.isPro || testPro; store.persist()
                if !store.wishlist.isEmpty && !ProcessInfo.processInfo.arguments.contains("-poster") { Notifier.requestAuth(); let hits = await store.checkWishlist(); Notifier.fireGrailAlert(hits) }
            }
            .onChange(of: pro.isPro) { _, v in store.isPro = v || testPro; store.persist() }
        }
    }
}
