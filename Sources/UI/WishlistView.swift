import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var store: Store
    @State private var showAdd = false
    @State private var checking = false

    var body: some View {
        NavigationStack {
            Group {
                if store.wishlist.isEmpty {
                    ScrollView {
                        EmptyState(icon: "flame", title: "Track your grails",
                                   message: "Add the pairs you're hunting and a target price. Soledex checks the market and alerts you when one drops to your number.",
                                   cta: "Add a grail") { showAdd = true }
                            .padding(.top, 70)
                    }
                } else { list }
            }
            .screenBg()
            .navigationTitle("Grails")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { showAdd = true } label: { Image(systemName: "plus").foregroundStyle(Theme.accent) } }
                if !store.wishlist.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { Task { checking = true; let hits = await store.checkWishlist(); Notifier.fireGrailAlert(hits); checking = false } } label: {
                            if checking { ProgressView().controlSize(.mini) } else { Image(systemName: "arrow.clockwise").foregroundStyle(Theme.inkMid) }
                        }
                    }
                }
            }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
            .sheet(isPresented: $showAdd) { AddWishSheet { store.addWish($0) } }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("We check the market when you open the app and alert you when a grail hits your target price.")
                    .font(.caption).foregroundStyle(Theme.inkMid).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                ForEach(store.wishlist) { w in
                    HStack(spacing: 12) {
                        ZStack { RoundedRectangle(cornerRadius: 12).fill(Color(hex: w.tint)).frame(width: 52, height: 52)
                            Image(systemName: "shoe.fill").foregroundStyle(.white.opacity(0.9)) }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(w.name).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                            Text("Target \(w.targetPrice.usd)").font(.system(size: 12)).foregroundStyle(Theme.inkMid)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(w.currentValue > 0 ? w.currentValue.usd : "—").font(Theme.display(16)).foregroundStyle(w.hitTarget ? Theme.good : Theme.ink).monospacedDigit()
                            if w.hitTarget { Chip(text: "Target hit", icon: "checkmark", color: Theme.good) }
                            else if w.currentValue > 0 { Text("\((w.currentValue - w.targetPrice).usd) to go").font(.system(size: 11)).foregroundStyle(Theme.inkLow) }
                        }
                    }
                    .card(12)
                    .overlay(alignment: .leading) { if w.hitTarget { RoundedRectangle(cornerRadius: 3).fill(Theme.good).frame(width: 4).padding(.vertical, 10) } }
                    .swipeActions { Button(role: .destructive) { store.removeWish(w) } label: { Label("Remove", systemImage: "trash") } }
                    .contextMenu { Button(role: .destructive) { store.removeWish(w) } label: { Label("Remove", systemImage: "trash") } }
                }
            }.padding(.horizontal, 16).padding(.vertical, 8)
        }
    }
}

struct AddWishSheet: View {
    var onAdd: (WishItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var target: Double = 0
    var body: some View {
        NavigationStack {
            Form {
                Section("Grail") { TextField("Sneaker name (e.g. Travis Scott Jordan 1 Low)", text: $name) }
                Section { HStack { Text("$").foregroundStyle(Theme.inkMid); TextField("Target price", value: $target, format: .number).keyboardType(.decimalPad) } }
                    header: { Text("Alert me when it drops to") }
                    footer: { Text("Soledex checks the eBay market and alerts you when this pair reaches your target.") }
            }
            .scrollContentBackground(.hidden).background(Theme.canvas)
            .navigationTitle("Add a grail").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Add") { onAdd(WishItem(name: name, query: name, targetPrice: target, currentValue: 0)); dismiss() }.fontWeight(.bold).foregroundStyle(Theme.accent).disabled(name.isEmpty || target <= 0) }
            }
        }
    }
}
