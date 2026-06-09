import SwiftUI

// Correction loop + notes — the thing thin scanners never offer.
struct CorrectionView: View {
    @State var item: Sneaker
    var onSave: (Sneaker) -> Void
    @Environment(\.dismiss) private var dismiss
    private let conditions = ["Deadstock (new)", "VNDS", "Used", "Beat"]
    private let editions = ["General Release", "Limited", "Collab", "Retro", "Sample"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $item.name)
                    TextField("Brand", text: $item.brand)
                    TextField("Model", text: $item.model)
                    TextField("Colorway", text: $item.colorway)
                    TextField("Style code", text: $item.styleCode)
                }
                Section("Size & condition") {
                    Picker("Size", selection: $item.size) { Text("—").tag(""); ForEach(SneakerSizes, id: \.self) { Text("US \($0)").tag($0) } }
                    Picker("Condition", selection: $item.condition) { ForEach(conditions, id: \.self) { Text($0) } }
                    Picker("Edition", selection: $item.edition) { ForEach(editions, id: \.self) { Text($0) } }
                }
                Section {
                    HStack {
                        Text("$").foregroundStyle(Theme.inkMid)
                        TextField("What you paid", value: $item.purchasePrice, format: .number).keyboardType(.decimalPad)
                    }
                } header: { Text("Cost") } footer: { Text("Add what you paid to track profit across your closet.") }
                Section("My notes") {
                    TextField("Colorway nickname, where you bought it…", text: $item.notes, axis: .vertical).lineLimit(2...4)
                }
            }
            .scrollContentBackground(.hidden).background(Theme.canvas)
            .navigationTitle("Fix details").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { onSave(item); dismiss() }.foregroundStyle(Theme.accent).fontWeight(.bold) }
            }
        }
    }
}
