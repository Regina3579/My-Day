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

                // The heading, a line with a heart, then the page.
                VStack(spacing: 12) {
                    Text(entry.displayTitle)
                        .font(.rounded(.title, weight: .heavy))
                        .foregroundStyle(Palette.berry)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    HeartDivider(lineLength: nil, heartSize: 22)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                if !entry.body.isEmpty {
                    Text(entry.body)
                        .font(.rounded(.body))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(5)
                        .textSelection(.enabled)
                }

                if entry.hasLittleWin {
                    LittleWinBanner(text: entry.littleWin, isToday: entry.date.isToday)
                }

                JournalPageExtras(entry: entry)
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

/// The page's little win, like a gold sticker: "🏆 Today's Little Win · Called my mom."
private struct LittleWinBanner: View {
    let text: String
    let isToday: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("🏆")
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.85)))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(isToday ? "Today's Little Win" : "My Little Win")
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Palette.cocoa.opacity(0.75))
                Text(text)
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Palette.cocoa)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.cream))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.butter, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}

/// The rest of a page: the weather and place, stickers, tags, the voice note and the
/// grateful, highlight and tomorrow lines.
private struct JournalPageExtras: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if entry.weather != nil || !entry.temperature.isEmpty || !entry.place.isEmpty {
                HStack(spacing: 8) {
                    if let weather = entry.weather {
                        chip(symbol: weather.symbol, multicolor: true,
                             text: entry.temperature.isEmpty ? weather.label : "\(weather.label) · \(entry.temperature)")
                    } else if !entry.temperature.isEmpty {
                        chip(symbol: "thermometer.medium", multicolor: false, text: entry.temperature)
                    }
                    if !entry.place.isEmpty {
                        chip(symbol: "mappin.circle.fill", multicolor: false, text: entry.place)
                    }
                }
            }
            if !entry.stickers.isEmpty {
                StickerRow(stickers: entry.stickers, size: 34)
            }
            if !entry.tags.isEmpty {
                TagChips(tags: entry.tags)
            }
            if let note = entry.voiceNote {
                VoiceNotePlayer(data: note)
            }
            line(art: "JournalJar", title: "I'm grateful for…", text: entry.gratitude)
            line(art: "JournalHighlightStar", title: "A highlight of my day…", text: entry.highlight)
            line(art: "JournalSprout", title: "I look forward to…", text: entry.lookingForward)
        }
    }

    private func chip(symbol: String, multicolor: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .symbolRenderingMode(multicolor ? .multicolor : .monochrome)
                .foregroundStyle(JournalStyle.pink)
            Text(text)
                .lineLimit(1)
        }
        .font(.rounded(.subheadline, weight: .bold))
        .foregroundStyle(JournalStyle.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(JournalStyle.pinkFill))
    }

    @ViewBuilder
    private func line(art: String, title: String, text: String) -> some View {
        if !text.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Image(art)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.rounded(.subheadline, weight: .heavy))
                        .foregroundStyle(JournalStyle.plum)
                    Text(text)
                        .font(.rounded(.body, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(JournalStyle.fieldFill))
            .accessibilityElement(children: .combine)
        }
    }
}
