import SwiftUI
import SwiftData

/// Reading one journal page.
struct JournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage(Prefs.journalLock) private var lockEnabled = false
    let entry: JournalEntry
    /// The page was just written: "Saved to your journal 💖" shows for a moment.
    var justSaved = false
    @State private var images: [UIImage] = []
    @State private var isEditing = false
    @State private var confirmDelete = false
    @State private var showsSaved = false

    var body: some View {
        Group {
            if lockEnabled && !appState.isJournalUnlocked {
                JournalLockView()
            } else {
                page
            }
        }
        .overlay(alignment: .bottom) {
            if showsSaved {
                Label("Saved to your journal 💖", systemImage: "checkmark.circle.fill")
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(JournalStyle.pinkGradient))
                    .shadow(color: JournalStyle.pink.opacity(0.35), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
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
                        Label("Move to Trash", systemImage: "trash")
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
        .confirmationDialog("Move this page to Trash?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Move to Trash", role: .destructive, action: moveToTrash)
        } message: {
            Text("You can restore it from Trash for \(JournalTrash.keepDays) days.")
        }
        .task { loadImages() }
        .task {
            guard justSaved else { return }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showsSaved = true }
            UIAccessibility.post(notification: .announcement, argument: "Saved to your journal")
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.easeInOut(duration: 0.3)) { showsSaved = false }
        }
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

                MoodBanner(mood: entry.mood, date: entry.date)

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

    private func moveToTrash() {
        JournalTrash.moveToTrash(entry)
        Haptics.tap()
        dismiss()
    }
}

/// The page's mood at the top: its little star, "Feeling Bored" in the mood's colour, and
/// when the page was written.
private struct MoodBanner: View {
    let mood: Mood
    let date: Date

    var body: some View {
        let colors = mood.chooserColors
        HStack(spacing: 14) {
            Image(mood.artName)
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 72)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("Feeling \(mood.label)")
                    .font(.rounded(.title2, weight: .heavy))
                    .foregroundStyle(colors.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.ink.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.rounded(.caption, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [colors.tile, colors.tile.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 1.5)
        )
        .shadow(color: mood.color.opacity(0.18), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feeling \(mood.label), \(date.formatted(date: .complete, time: .shortened))")
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

/// The rest of a page: the weather and place, stickers, tags, the voice notes and the
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
            let voiceNotes = entry.sortedVoiceNotes
            let voiceCount = voiceNotes.count + (entry.voiceNote == nil ? 0 : 1)
            if let earlier = entry.voiceNote {
                VoiceNotePlayer(data: earlier, title: VoiceNoteDraft.title(index: 0, count: voiceCount))
            }
            ForEach(Array(voiceNotes.enumerated()), id: \.element.persistentModelID) { index, note in
                VoiceNotePlayer(data: note.audio,
                                title: VoiceNoteDraft.title(index: index + voiceCount - voiceNotes.count, count: voiceCount),
                                duration: note.duration, recordedAt: note.createdAt)
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
