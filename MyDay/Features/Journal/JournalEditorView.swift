import SwiftUI
import SwiftData
import PhotosUI

/// Write or edit a journal page: mood, title, text, prompts and a photo.
struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let entry: JournalEntry?
    @State private var date: Date
    @State private var title: String
    @State private var text: String
    @State private var mood: Mood
    @State private var isFavorite: Bool
    @State private var photoData: Data?
    @State private var thumbnailData: Data?
    @State private var preview: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @FocusState private var textFocused: Bool

    private let prompts = [
        "Today I'm grateful for…",
        "A beautiful moment today…",
        "Something that made me smile…",
        "Something I learned…",
        "Tomorrow I want to…"
    ]

    init(entry: JournalEntry?, date: Date) {
        self.entry = entry
        _date = State(initialValue: entry?.date ?? date)
        _title = State(initialValue: entry?.title ?? "")
        _text = State(initialValue: entry?.body ?? "")
        _mood = State(initialValue: entry?.mood ?? .happy)
        _isFavorite = State(initialValue: entry?.isFavorite ?? false)
        _photoData = State(initialValue: entry?.photoData)
        _thumbnailData = State(initialValue: entry?.thumbnailData)
        _preview = State(initialValue: entry?.photoData.flatMap(UIImage.init(data:)))
    }

    private var canSave: Bool { !title.trimmed.isEmpty || !text.trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    moodCard
                    writingCard
                    photoCard
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
                        .disabled(!canSave)
                }
            }
            .onChange(of: pickerItem) { _, item in
                loadPhoto(item)
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
                                .padding(.vertical, 7)
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

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A photo of the moment")
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(Palette.berry)

            if let preview {
                Color.clear
                    .frame(height: 210)
                    .frame(maxWidth: .infinity)
                    .overlay(Image(uiImage: preview).resizable().scaledToFill())
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            withAnimation {
                                self.preview = nil
                                photoData = nil
                                thumbnailData = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white, Color.black.opacity(0.45))
                        }
                        .padding(10)
                        .accessibilityLabel("Remove photo")
                    }
            }

            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack(spacing: 8) {
                    if isLoadingPhoto {
                        ProgressView()
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                    Text(preview == nil ? "Add a photo" : "Change photo")
                }
                .font(.rounded(.subheadline, weight: .bold))
                .foregroundStyle(Palette.hotPink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Palette.hotPink.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )
            }
            .disabled(isLoadingPhoto)
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

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingPhoto = true
        Task {
            let raw = try? await item.loadTransferable(type: Data.self)
            let prepared = await Task.detached(priority: .userInitiated) {
                raw.flatMap(PhotoProcessor.prepare)
            }.value
            if let prepared {
                photoData = prepared.photo
                thumbnailData = prepared.thumbnail
                withAnimation { preview = UIImage(data: prepared.photo) }
            }
            isLoadingPhoto = false
            pickerItem = nil
        }
    }

    private func save() {
        guard canSave else { return }
        let page = entry ?? JournalEntry(date: date)
        page.date = date
        page.title = title.trimmed
        page.body = text.trimmed
        page.mood = mood
        page.isFavorite = isFavorite
        page.photoData = photoData
        page.thumbnailData = thumbnailData
        page.updatedAt = .now
        if entry == nil {
            context.insert(page)
        }
        Haptics.success()
        dismiss()
    }
}
