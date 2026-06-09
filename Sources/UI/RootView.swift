import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0
    @State private var showSettings = false
    @State private var demoResult: Bool
    @State private var demoPaywall: Bool

    init() {
        let a = ProcessInfo.processInfo.arguments
        var t = 0; if let i = a.firstIndex(of: "-tab"), a.indices.contains(i+1), let n = Int(a[i+1]) { t = n }
        _tab = State(initialValue: t)
        _demoResult = State(initialValue: a.contains("-result"))
        _demoPaywall = State(initialValue: a.contains("-paywall"))
    }

    var body: some View {
        TabView(selection: $tab) {
            ScanHomeView(showSettings: $showSettings).tabItem { Label("Scan", systemImage: "camera.viewfinder") }.tag(0)
            CollectionView().tabItem { Label("Closet", systemImage: "square.grid.2x2") }.tag(1)
            WishlistView().tabItem { Label("Grails", systemImage: "flame") }.tag(2).badge(store.wishHits.count)
        }
        .fullScreenCover(isPresented: $store.showScan) { ScanView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .fullScreenCover(isPresented: $demoResult) { ResultView(item: Sample.items[0], onClose: { demoResult = false }) }
        .sheet(isPresented: $demoPaywall) { PaywallView() }
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-scan") { store.showScan = true } }
    }
}
