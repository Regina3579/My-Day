import SwiftUI

/// "Reorder Categories", from pressing and holding a category on the To-Dos screen: drag the
/// categories by their ≡ handles into the order the row at the top should show them. Done keeps
/// the new order; Reset puts them back in My Day's own order.
struct ReorderCategoriesSheet: View {
    /// Called with the new order when the person taps Done.
    let onSave: ([CategoryChoice]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rows: [CategoryChoice]
    /// The order before any reordering, for Reset.
    private let standard: [CategoryChoice]

    init(categories: [CategoryChoice], standard: [CategoryChoice], onSave: @escaping ([CategoryChoice]) -> Void) {
        _rows = State(initialValue: categories)
        self.standard = standard
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(rows, id: \.key) { choice in
                        HStack(spacing: 12) {
                            CategoryIcon(choice: choice, size: 28)
                                .accessibilityHidden(true)
                            Text(choice.label)
                                .font(.rounded(.body, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(.vertical, 2)
                    }
                    .onMove { source, destination in
                        rows.move(fromOffsets: source, toOffset: destination)
                        Haptics.tap()
                    }
                } footer: {
                    Text("Drag a category by its handle. The first one comes right after All.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(rows)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset to My Day's Order") {
                        withAnimation(.snappy) { rows = standard }
                    }
                    .disabled(rows.map(\.key) == standard.map(\.key))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
