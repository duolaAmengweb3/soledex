import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var front: UIImage?
    @State private var extra: UIImage?
    @State private var activeSlot = 0
    @State private var showSource = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var pick: PhotosPickerItem?
    @State private var analyzing = false
    @State private var result: Sneaker?
    @State private var error: String?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if analyzing {
                    Spacer()
                    VStack(spacing: 14) { ProgressView().controlSize(.large).tint(Theme.accent)
                        Text("Identifying & pricing…").font(.callout).foregroundStyle(Theme.inkMid) }
                    Spacer()
                } else {
                    HStack(spacing: 12) {
                        slot(image: front, label: "Front", required: true, idx: 0)
                        slot(image: extra, label: "Box / size tag", required: false, idx: 1)
                    }.padding(.top, 8)
                    Text("Add a second photo of the box or size tag for a more accurate ID.")
                        .font(.caption).foregroundStyle(Theme.inkLow).multilineTextAlignment(.center)

                    if let error { Text(error).font(.footnote).foregroundStyle(Theme.warn).multilineTextAlignment(.center) }
                    if !store.isPro { Text("\(store.scansLeftToday) free scans left today").font(.caption).foregroundStyle(Theme.inkLow) }

                    Button { runIdentify() } label: { HStack(spacing: 9) { Image(systemName: "sparkle.magnifyingglass"); Text("Identify") } }
                        .buttonStyle(BlazeButton()).disabled(front == nil)
                    Spacer()
                }
            }
            .padding(.horizontal, 18)
            .screenBg()
            .navigationTitle("Scan").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundStyle(Theme.inkMid) } } }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
            .confirmationDialog("Add photo", isPresented: $showSource, titleVisibility: .hidden) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showLibrary = true }
            }
            .fullScreenCover(isPresented: $showCamera) { CameraPicker { setSlot($0) }.ignoresSafeArea() }
            .photosPicker(isPresented: $showLibrary, selection: $pick, matching: .images)
            .fullScreenCover(item: $result) { item in ResultView(item: item, onClose: { result = nil; dismiss() }) }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: pick) { _, v in Task { if let v, let d = try? await v.loadTransferable(type: Data.self), let img = UIImage(data: d) { setSlot(img) }; pick = nil } }
        }
    }

    private func slot(image: UIImage?, label: String, required: Bool, idx: Int) -> some View {
        Button { error = nil; activeSlot = idx; showSource = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(style: StrokeStyle(lineWidth: 2, dash: image == nil ? [8,6] : []))
                        .foregroundStyle(image == nil ? Theme.accent.opacity(0.45) : Theme.hairline))
                if let image {
                    Image(uiImage: image).resizable().scaledToFill().clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: idx == 0 ? "shippingbox" : "barcode.viewfinder").font(.system(size: 32)).foregroundStyle(Theme.accent.opacity(0.8))
                        Text(label).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.inkMid)
                        if !required { Text("optional").font(.caption2).foregroundStyle(Theme.inkLow) }
                    }
                }
            }
        }.buttonStyle(.plain).frame(height: 220).frame(maxWidth: .infinity)
    }

    private func setSlot(_ img: UIImage) { if activeSlot == 0 { front = img } else { extra = img } }

    private func runIdentify() {
        guard let front else { return }
        guard store.canScan else { showPaywall = true; return }
        guard let fd = front.jpegForUpload() else { return }
        let bd = extra?.jpegForUpload()
        analyzing = true; error = nil
        let frontImg = front
        Task {
            do {
                var c = try await SoledexAPI.identify(fd, back: bd)
                c.imageFile = PhotoStore.save(frontImg)
                store.recordScan(); analyzing = false; result = c
            }
            catch { analyzing = false; self.error = (error as? LocalizedError)?.errorDescription ?? "Couldn't read that photo. Try again." }
        }
    }
}
