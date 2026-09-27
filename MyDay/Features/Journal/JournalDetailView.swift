import SwiftUI
import SwiftData

/// Reading one journal page.
struct JournalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    let entry: JournalEntry
    @State private var images: [UIImage] = []
    @State private var isEditing = false
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if lockEnabled && !appState.isJournalUnlocked {
                JournalLockView()
            } else {
                page
            }
        }
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .journal))
        .navigationTitle(entry.date.formatted(.dateTime.month(.abbreviated).day().year()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    entry.isFavorite.toggle()
                    Haptics.tap()
                } label: {
                    Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                }
                .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")

                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit Page", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Page", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .sheet(isPresented: $isEditing, onDismiss: { loadImages() }) {
            NewJournalEntrySheet(entry: entry)
        }
        .confirmationDialog("Delete this page?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Page", role: .destructive, action: deleteEntry)
        } message: {
            Text("This can't be undone.")
        }
        .task { loadImages() }
    }

    private var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !images.isEmpty {
                    TabView {
                        ForEach(images.indices, id: \.self) { index in
                            Color.clear
                                .overlay(Image(uiImage: images[index]).resizable().scaledToFill())
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .padding(.horizontal, 2)
                                .accessibilityLabel("Photo \(index + 1) of \(images.count)")
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .always : .never))
                    .frame(height: 280)
                    .shadow(color: Palette.hotPink.opacity(0.25), radius: 12, x: 0, y: 6)
                }

                HStack(spacing: 8) {
                    Text("\(entry.mood.emoji) \(entry.mood.label)")
                        .font(.rounded(.subheadline, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(entry.mood.color.opacity(0.25)))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.rounded(.caption, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }

                Text(entry.displayTitle)
                    .font(.rounded(.title, weight: .heavy))
                    .foregroundStyle(Palette.berry)

                HeartUnderline(width: 90)

                Text(entry.body)
                    .font(.rounded(.body))
                    .foregroundStyle(Palette.ink)
                    .lineSpacing(5)
                    .textSelection(.enabled)
            }
            .cuteCard(tint: Palette.hotPink, padding: 20)
            .padding(18)
        }
    }

    private func loadImages() {
        images = entry.sortedPhotos.compactMap { UIImage(data: $0.imageData) }
    }

    private func deleteEntry() {
        dismiss()
        // Delete after the pop animation, so no view reads the removed model.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            context.delete(entry)
        }
    }
}
