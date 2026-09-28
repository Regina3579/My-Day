import SwiftUI
import SwiftData
import PhotosUI

/// Write a new journal page, or edit an existing one: mood, little win, title, text, prompts and photos.
struct NewJournalEntrySheet: View {
    /// A photo shown in the editor: either already saved, or just picked.
    private struct PhotoDraft: Identifiable {
        let id = UUID()
        let existing: JournalPhoto?
        let imageData: Data
        let thumbnailData: Data?
        let preview: UIImage?
    }

    private static let maxPhotos = 6

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let entry: JournalEntry?
    @State private var date: Date
    @State private var title: String
    @State private var text: String
    @State private var mood: Mood
    @State private var isFavorite: Bool
    @State private var littleWin: String
    @State private var photos: [PhotoDraft]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @FocusState private var textFocused: Bool

    private let prompts = [
        "Today I'm grateful for…",
        "A beautiful moment today…",
        "Something that made me smile…",
        "Something I learned…",
        "Tomorrow I want to…"
    ]

    /// A new page dated `date`.
    init(date: Date) {
        entry = nil
        _date = State(initialValue: date)
        _title = State(initialValue: "")
        _text = State(initialValue: "")
        _mood = State(initialValue: .happy)
        _isFavorite = State(initialValue: false)
        _littleWin = State(initialValue: "")
        _photos = State(initialValue: [])
    }

    /// Edit an existing page.
    init(entry: JournalEntry) {
        self.entry = entry
        _date = State(initialValue: entry.date)
        _title = State(initialValue: entry.title)
        _text = State(initialValue: entry.body)
        _mood = State(initialValue: entry.mood)
        _isFavorite = State(initialValue: entry.isFavorite)
        _littleWin = State(initialValue: entry.littleWin)
        _photos = State(initialValue: entry.sortedPhotos.map { photo in
            PhotoDraft(existing: photo, imageData: photo.imageData, thumbnailData: photo.thumbnailData,
                       preview: photo.thumbnailData.flatMap(UIImage.init(data:)))
        })
    }

    private var canSave: Bool {
        !title.trimmed.isEmpty || !text.trimmed.isEmpty || !littleWin.trimmed.isEmpty || !photos.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    moodCard
                    littleWinCard
                    writingCard
                    photosCard
                }
                .padding(18)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(DreamyBackground(theme: .journal))
            .navigationTitle(entry == nil ? "New Page" : "Edit Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.bold)
                        .disabled(!canSave || isLoadingPhotos)
                }
            }
            .onChange(of: pickerItems) { _, items in
                loadPhotos(items)
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Cards

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How are you feeling?")
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Palette.berry)
                Spacer()
                Button {
                    isFavorite.toggle()
                    Haptics.tap()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(Palette.hotPink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(isFavorite ? "Favorite page" : "Mark as favorite")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(Mood.allCases) { option in
                    let isSelected = option == mood
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { mood = option }
                        Haptics.tap()
                    } label: {
                        VStack(spacing: 2) {
                            Text(option.emoji).font(.system(size: 28))
                            Text(option.label)
                                .font(.rounded(.caption2, weight: .semibold))
                                .foregroundStyle(Palette.inkSoft)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? option.color.opacity(0.25) : Color.white.opacity(0.6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isSelected ? option.color : Color.clear, lineWidth: 2)
                        )
                        .scaleEffect(isSelected ? 1.05 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.label)
                    .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : [])
                }
            }
        }
        .cuteCard(tint: Palette.hotPink)
    }

    private var winPrompt: String { "🌟 My little win \(date.isToday ? "today" : "that day")…" }

    /// Today's Little Win: one optional line, like "Finished my workout." or "Called my mom."
    private var littleWinCard: some View {
        HStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().strokeBorder(Palette.butter, lineWidth: 1.5))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(date.isToday ? "Today's Little Win" : "My Little Win")
                        .font(.rounded(.subheadline, weight: .bold))
                        .foregroundStyle(Palette.cocoa)
                    Spacer(minLength: 8)
                    Text("Optional")
                        .font(.rounded(.caption2, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                TextField(winPrompt, text: $littleWin)
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .submitLabel(.done)
            }
        }
        .cuteCard(tint: Palette.honey, padding: 14)
    }

    private var writingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(selection: $date) {
                Label("When", systemImage: "calendar")
                    .font(.rounded(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
            }

            TextField("Give this page a title", text: $title)
                .font(.rounded(.title3, weight: .bold))
                .foregroundStyle(Palette.berry)

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(prompts, id: \.self) { prompt in
                        Button {
                            insert(prompt)
                        } label: {
                            Text(prompt)
                                .font(.rounded(.caption, weight: .semibold))
                                .foregroundStyle(Palette.berry)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Palette.blush))
                        }
                        .buttonStyle(PressScaleStyle())
                    }
                }
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Capture your thoughts and beautiful moments…")
                        .font(.rounded(.body))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.rounded(.body))
                    .foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 220)
                    .focused($textFocused)
            }
        }
        .cuteCard(tint: Palette.hotPink)
    }

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos of the moment")
                    .font(.rounded(.headline, weight: .bold))
                    .foregroundStyle(Palette.berry)
                Spacer()
                Text("\(photos.count)/\(Self.maxPhotos)")
                    .font(.rounded(.caption, weight: .bold))
                    .foregroundStyle(Palette.inkSoft)
            }

            if !photos.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(photos) { photo in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if let preview = photo.preview {
                                    Image(uiImage: preview).resizable().scaledToFill()
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    withAnimation(.snappy) { photos.removeAll { $0.id == photo.id } }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.white, Color.black.opacity(0.45))
                                        .frame(width: 36, height: 36)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Remove photo")
                            }
                    }
                }
            }

            if photos.count < Self.maxPhotos {
                PhotosPicker(selection: $pickerItems, maxSelectionCount: Self.maxPhotos - photos.count,
                             matching: .images) {
                    HStack(spacing: 8) {
                        if isLoadingPhotos {
                            ProgressView()
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                        }
                        Text(photos.isEmpty ? "Add photos" : "Add more photos")
                    }
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.hotPink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Palette.hotPink.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .disabled(isLoadingPhotos)
            }
        }
        .cuteCard(tint: Palette.hotPink)
    }

    // MARK: Actions

    private func insert(_ prompt: String) {
        let separator = (text.isEmpty || text.hasSuffix("\n")) ? "" : "\n\n"
        text += separator + prompt + " "
        textFocused = true
        Haptics.tap()
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isLoadingPhotos = true
        Task {
            for item in items {
                let raw = try? await item.loadTransferable(type: Data.self)
                let prepared = await Task.detached(priority: .userInitiated) {
                    raw.flatMap(PhotoProcessor.prepare)
                }.value
                if let prepared, photos.count < Self.maxPhotos {
                    let draft = PhotoDraft(existing: nil, imageData: prepared.photo,
                                           thumbnailData: prepared.thumbnail,
                                           preview: UIImage(data: prepared.thumbnail))
                    withAnimation(.snappy) { photos.append(draft) }
                }
            }
            isLoadingPhotos = false
            pickerItems = []
        }
    }

    private func save() {
        guard canSave else { return }
        let page = entry ?? JournalEntry(date: date)
        if entry == nil {
            context.insert(page)
        }
        page.date = date
        page.title = title.trimmed
        page.body = text.trimmed
        page.mood = mood
        page.isFavorite = isFavorite
        page.littleWin = littleWin.trimmed
        page.updatedAt = .now

        // Remove photos that were taken out, keep the rest in the new order, add new ones.
        let kept = Set(photos.compactMap { $0.existing?.persistentModelID })
        for photo in page.sortedPhotos where !kept.contains(photo.persistentModelID) {
            context.delete(photo)
        }
        for (index, draft) in photos.enumerated() {
            if let existing = draft.existing {
                existing.order = index
            } else {
                let photo = JournalPhoto(imageData: draft.imageData, thumbnailData: draft.thumbnailData, order: index)
                context.insert(photo)
                photo.entry = page
            }
        }

        Haptics.success()
        dismiss()
    }
}
