import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.isPro { Label("Soledex Pro — unlocked", systemImage: "crown.fill").foregroundStyle(Theme.accent) }
                    else {
                        Button { showPaywall = true } label: { Label("Unlock Soledex Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent) }
                        Button { Task { await pro.restore() } } label: { Label("Restore purchase", systemImage: "arrow.clockwise").foregroundStyle(Theme.ink) }
                    }
                }
                Section {
                    Link(destination: URL(string: "https://duolaamengweb3.github.io/soledex/privacy.html")!) { Label("Privacy", systemImage: "hand.raised") }
                    Link(destination: URL(string: "https://duolaamengweb3.github.io/soledex/support.html")!) { Label("Support", systemImage: "envelope") }
                } footer: { Text("Your photos are sent only to identify and value the item, never stored or shared. Your collection stays on your device. Values are estimates, not a formal appraisal.") }
            }
            .scrollContentBackground(.hidden).background(Theme.canvas)
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(Theme.accent) } }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}
