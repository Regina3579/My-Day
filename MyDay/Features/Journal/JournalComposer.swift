import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Colours for the journal, sampled from the design and made a little more vivid.
enum JournalStyle {
    static let plum = Color(hex: 0x6E0B5A)          // section titles
    static let ink = Palette.ink
    static let soft = Color(hex: 0x6A5696)          // notes
    static let placeholder = Color(hex: 0x8A73A8)
    static let label = Color(hex: 0x412A74)         // extras labels
    static let moodLabel = Color(hex: 0x65508F)
    static let pink = Color(hex: 0xF2148E)
    static let pinkFill = Color(hex: 0xFCE0F3)
    static let purple = Color(hex: 0x7D3BFC)
    static let fieldFill = Color(hex: 0xFDF3FA)
    static let selectedMoodFill = Color(hex: 0xFDDEEF)
    static let selectedMoodEdge = Color(hex: 0xF042A7)
    static let pinkGradient = LinearGradient(colors: [Color(hex: 0xFF6FB5), Color(hex: 0xF2148E)],
                                             startPoint: .top, endPoint: .bottom)
    static let purpleGradient = LinearGradient(colors: [Color(hex: 0xA77BFF), Color(hex: 0x7D3BFC)],
                                               startPoint: .top, endPoint: .bottom)
}

extension View {
    /// A white, softly glowing journal card.
    func journalCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.8)))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.white, lineWidth: 1.5))
            .shadow(color: JournalStyle.pink.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Scene

/// A picture at the top of a journal screen. Its first rows are soft curtains for the status
/// bar, and the panel below covers its last rows.
struct JournalScene {
    let imageName: String
    let imageSize: CGSize
    /// The row (px) where the design's back and ⋮ buttons sit: it lines up with the
    /// navigation bar's buttons.
    let buttonsRow: CGFloat
    /// The rows the panel covers.
    let overlapRows: CGFloat
    let accessibilityLabel: String
    /// Where the title's words begin (px), for a picture whose title rises to just under the
    /// Dynamic Island (its back and ⋮ buttons float in the clock's row above it).
    var titleRow: CGFloat?

    /// Writing a page: the "My Journal — A safe space for your thoughts, feelings and
    /// beautiful moments" sign, the girl, the puppy, the kitten and the books.
    static let composer = JournalScene(
        imageName: "JournalScene", imageSize: CGSize(width: 854, height: 563), buttonsRow: 225, overlapRows: 40,
        accessibilityLabel: "My Journal. A safe space for your thoughts, feelings and beautiful moments.")

    /// My Journal Pages: its title, the girl and her puppy, the books and "A Happier Me
    /// Everyday". The panel covers the table at the bottom, up to the puppy's paws (its face
    /// stays in view), and Write a new page sits right at the panel's top.
    static let pages = JournalScene(
        imageName: "JournalPagesScene", imageSize: CGSize(width: 853, height: 570), buttonsRow: 213, overlapRows: 44,
        accessibilityLabel: "My Journal Pages. Every thought and beautiful moment belongs here.", titleRow: 258)

    func scale(width: CGFloat) -> CGFloat {
        width / imageSize.width
    }

    func topRow(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        if let titleRow {
            // The title's top just under the Dynamic Island (or 58 points down without one).
            return max(0, titleRow - max(statusBar - 2, 58) / scale(width: width))
        }
        return max(0, buttonsRow - (statusBar + 22) / scale(width: width))
    }

    func height(width: CGFloat, statusBar: CGFloat) -> CGFloat {
        (imageSize.height - topRow(width: width, statusBar: statusBar)) * scale(width: width)
    }

    func overlap(width: CGFloat) -> CGFloat {
        overlapRows * scale(width: width)
    }

    /// The height of the status bar (and the Dynamic Island), from the app's window.
    @MainActor
    static func windowStatusBar(fallback: CGFloat) -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        return window?.safeAreaInsets.top ?? fallback
    }
}

struct JournalHero: View {
    var scene: JournalScene = .composer
    let width: CGFloat
    /// Height of the status bar (0 in a sheet).
    let statusBar: CGFloat

    var body: some View {
        let scale = scene.scale(width: width)
        let top = scene.topRow(width: width, statusBar: statusBar)
        Image(scene.imageName)
            .resizable()
            .frame(width: width, height: scene.imageSize.height * scale)
            .offset(y: -top * scale)
            .frame(width: width, height: scene.height(width: width, statusBar: statusBar), alignment: .top)
            .clipped()
            .accessibilityElement()
            .accessibilityLabel(scene.accessibilityLabel)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Blush behind the journal, and the soft panel (rounded at the top) that holds the cards.
struct JournalBackdrop: View {
    static let base = Color(hex: 0xFDE7F1)

    var body: some View {
        LinearGradient(colors: [Self.base, Color(hex: 0xFCEAF3), Color(hex: 0xFDF0F5)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct JournalPanel: View {
    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0xFFF4F9), JournalBackdrop.base, Color(hex: 0xFDEEF4)],
                                 startPoint: .top, endPoint: .bottom))
            .shadow(color: JournalStyle.pink.opacity(0.14), radius: 8, x: 0, y: -6)
    }
}

// MARK: - Composer

/// Writing a journal page, as in the design: the day and its weather, "How are you feeling
/// today?" (six moods, and ＋ for all thirty), "Write about your day…" (a heading, a line with a heart, then the writing), the
/// extras (photos, stickers, a voice note, the place, the weather and tags), what you're
/// grateful for, the day's highlight, what you look forward to, your little win, and Save
/// Journal Entry. It is the full page behind "Write a new page" (`.page`: once saved, the
/// written page takes its place) and the edit-page sheet (`.sheet`).
struct JournalComposer: View {
    enum Presentation {
        case page, sheet
    }

    /// A photo on the page: already saved, or just picked.
    private struct PhotoDraft: Identifiable {
        let id = UUID()
        let existing: JournalPhoto?
        let imageData: Data
        let thumbnailData: Data?
        let preview: UIImage?
    }

    private enum Extra: String, Identifiable {
        case date, moods, sticker, voice, place, weather, tags
        var id: String { rawValue }
    }

    static let maxPhotos = 6
    /// Words on a page without My Day Pro (Pro has no limit).
    static let wordLimit = 250
    static let headingLimit = 60

    let presentation: Presentation

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(RatingPrompt.self) private var rating
    @Environment(MyDayPro.self) private var pro
    @Environment(\.hostTab) private var hostTab

    /// The page being edited: nil for a new page until it is first saved.
    @State private var entry: JournalEntry?
    @State private var date: Date
    /// The page's heading, like "A wonderful day" ("" when not written).
    @State private var title: String
    @State private var text: String
    @State private var mood: Mood
    /// A mood was chosen (a page can be saved with just its mood).
    @State private var moodPicked: Bool
    @State private var isFavorite: Bool
    @State private var littleWin: String
    @State private var gratitude: String
    @State private var highlight: String
    @State private var lookingForward: String
    @State private var stickers: String
    @State private var tags: [String]
    /// "What have you been up to?" and "My Goals": what is ticked for the day, the lists as the
    /// person has them, and the list being edited.
    @State private var upTo: Set<String>
    @State private var goalsMet: Set<String>
    @State private var activityItems = DayListKind.activities.items
    @State private var goalItems = DayListKind.goals.items
    @State private var editingList: DayListKind?
    @State private var place: String
    @State private var weather: JournalWeather?
    @State private var temperature: String
    @State private var voiceNotes: [VoiceNoteDraft]
    /// The voice note the Voice Notes sheet records onto when it opens (its Continue button).
    @State private var voiceContinuing: VoiceNoteDraft.ID?
    @State private var photos: [PhotoDraft]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var extra: Extra?
    /// A Pro feature tapped by a free account: its My Day Pro pop-up.
    @State private var proOffer: ProFeature?
    /// Whether this page has already offered unlimited writing (once, when the free limit is
    /// first reached).
    @State private var heroIsVisible = true
    @State private var toast: String?
    @FocusState private var headingFocused: Bool
    @FocusState private var textFocused: Bool
    /// Set while the yellow 🎙 in the writing box is listening.
    @State private var isDictating = false
    /// The first-time tip pointing at the ＋ for more moods.
    @AppStorage(Prefs.didShowMoodTip) private var didShowMoodTip = false
    @State private var showsMoodTip = false
    /// The first-time tip pointing at Get a Prompt, after the moods tip.
    @AppStorage(Prefs.didShowPromptTip) private var didShowPromptTip = false
    @State private var showsPromptTip = false
    /// Where Get a Prompt and the page's bottom are on screen, so its tip only comes when there
    /// is room for it (the page scrolls up first when there isn't).
    @State private var promptFrame = CGRect.zero
    @State private var pageBottom: CGFloat = 0
    @State private var tipScrollTarget: String?

    /// Edits `entry`, or starts a new page dated `date` when it is nil (from `template`'s
    /// heading, prompts and tags when one is given).
    init(entry: JournalEntry?, date: Date, presentation: Presentation, template: JournalPageTemplate? = nil) {
        self.presentation = presentation
        _entry = State(initialValue: entry)
        _date = State(initialValue: entry?.date ?? date)
        _title = State(initialValue: entry?.title ?? template?.heading ?? "")
        _text = State(initialValue: entry?.body ?? template?.starter ?? "")
        _mood = State(initialValue: entry?.mood ?? .happy)
        _moodPicked = State(initialValue: entry != nil)
        _isFavorite = State(initialValue: entry?.isFavorite ?? false)
        _littleWin = State(initialValue: entry?.littleWin ?? "")
        _gratitude = State(initialValue: entry?.gratitude ?? "")
        _highlight = State(initialValue: entry?.highlight ?? "")
        _lookingForward = State(initialValue: entry?.lookingForward ?? "")
        _stickers = State(initialValue: entry?.stickers ?? "")
        _tags = State(initialValue: entry?.tags ?? template?.tags ?? [])
        _upTo = State(initialValue: Set(entry?.activities ?? []))
        _goalsMet = State(initialValue: Set(entry?.goals ?? []))
        _place = State(initialValue: entry?.place ?? "")
        _weather = State(initialValue: entry?.weather)
        _temperature = State(initialValue: entry?.temperature ?? "")
        _voiceNotes = State(initialValue: VoiceNoteDraft.drafts(of: entry))
        _photos = State(initialValue: (entry?.sortedPhotos ?? []).map { photo in
            PhotoDraft(existing: photo, imageData: photo.imageData, thumbnailData: photo.thumbnailData,
                       preview: photo.thumbnailData.flatMap(UIImage.init(data:)))
        })
    }

    private var canSave: Bool {
        moodPicked || !photos.isEmpty || !voiceNotes.isEmpty || weather != nil || !tags.isEmpty || !stickers.isEmpty
            || ![title, text, littleWin, gratitude, highlight, lookingForward, place].allSatisfy { $0.trimmed.isEmpty }
    }

    var body: some View {
        page
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Journal")
                        .font(.rounded(.headline, weight: .bold))
                        .foregroundStyle(JournalStyle.ink)
                        .opacity(heroIsVisible ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: heroIsVisible)
                        .accessibilityHidden(heroIsVisible)
                }
                if presentation == .page {
                    ToolbarItem(placement: .topBarTrailing) {
                        moreMenu
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        // A round ✕, like the page's back button, so the picture's title stays clear.
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(JournalStyle.pink)
                        }
                        .accessibilityLabel("Cancel")
                    }
                }
            }
            .navigationTitle("My Journal")
            .navigationBarTitleDisplayMode(.inline)
            // The picture shows clear right up to the top: no bar background over it (soft pink
            // once it has scrolled away, so the page doesn't run under the title).
            .toolbarBackground(heroIsVisible ? .hidden : .visible, for: .navigationBar)
            .toolbarBackground(JournalBackdrop.base, for: .navigationBar)
            .sheet(item: $editingList) { kind in
                DayListEditor(kind: kind) {
                    activityItems = DayListKind.activities.items
                    goalItems = DayListKind.goals.items
                }
            }
            .sheet(item: $extra) { extra in
                extraSheet(extra)
            }
            .proOffer($proOffer)
            .onChange(of: pickerItems) { _, items in
                loadPhotos(items)
            }
            .onChange(of: text) { old, new in
                // Without My Day Pro, a page holds 250 words: writing past them stops at the
                // 250th (an older, longer page keeps its words but can't grow), and every time
                // it happens the Unlock Unlimited Writing pop-up appears. Pro has no limit.
                guard !pro.isActive else { return }
                let words = JournalWords.count(new)
                guard words > Self.wordLimit, words > JournalWords.count(old) else { return }
                text = JournalWords.count(old) <= Self.wordLimit ? JournalWords.prefix(new, words: Self.wordLimit) : old
                textFocused = false
                if proOffer == nil {
                    proOffer = .unlimitedWriting
                }
            }
            .onChange(of: title) { old, new in
                if new.count > Self.headingLimit, old.count <= Self.headingLimit {
                    title = String(new.prefix(Self.headingLimit))
                }
            }
            .onAppear {
                if presentation == .page { router.setFullScreen(true, in: hostTab) }
            }
            .onDisappear {
                if presentation == .page { router.setFullScreen(false, in: hostTab) }
            }
    }

    private var page: some View {
        GeometryReader { proxy in
            ScrollViewReader { reader in
                scroller(proxy)
                    .onChange(of: tipScrollTarget) { _, target in
                        guard let target else { return }
                        withAnimation(.easeInOut(duration: 0.45)) { reader.scrollTo(target, anchor: .top) }
                    }
                #if DEBUG
                    .task {
                        if DebugLaunchRoute.takeJournalMoods() {
                            try? await Task.sleep(for: .seconds(1))
                            extra = .moods
                        }
                        if DebugLaunchRoute.takeJournalVoice() {
                            try? await Task.sleep(for: .seconds(1))
                            extra = .voice
                        }
                        if DebugLaunchRoute.takeJournalStickers() {
                            try? await Task.sleep(for: .seconds(1))
                            extra = .sticker
                        }
                        guard let anchor = DebugLaunchRoute.takeJournalAnchor() else { return }
                        try? await Task.sleep(for: .seconds(1))
                        reader.scrollTo(anchor, anchor: anchor == "save" ? .bottom : .top)
                        if let offer = DebugLaunchRoute.takeProOffer() {
                            // `pro-reflections`: a free account tapped a reflection.
                            try? await Task.sleep(for: .seconds(1))
                            proOffer = offer
                        }
                    }
                #endif
            }
        }
        .background(JournalBackdrop())
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.rounded(.headline, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(JournalStyle.pinkGradient))
                    .shadow(color: JournalStyle.pink.opacity(0.35), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .overlayPreferenceValue(MoodPlusAnchorKey.self) { anchor in
            if showsMoodTip, let anchor {
                GeometryReader { proxy in
                    MoodTip(plusFrame: proxy[anchor], size: proxy.size,
                            onOpen: openMoodsFromTip, onDismiss: closeMoodTip)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .overlayPreferenceValue(PromptButtonAnchorKey.self) { anchor in
            if showsPromptTip, let anchor {
                GeometryReader { proxy in
                    PromptTip(buttonFrame: proxy[anchor], size: proxy.size,
                              onTry: tryPromptFromTip, onDismiss: closePromptTip)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.frame(in: .global).maxY
        } action: { bottom in
            pageBottom = bottom
        }
        .onChange(of: extra) { _, sheet in
            // The moods tip's ＋ (or anything else) opened a sheet: the prompt tip waits for it.
            guard sheet == nil, didShowMoodTip, !didShowPromptTip else { return }
            Task {
                try? await Task.sleep(for: .seconds(0.7))
                await showPromptTipIfNew()
            }
        }
        .task { await showTipsIfNew() }
    }

    // MARK: First-time tips

    /// The first time a page is written: once it has been open a moment, point at the ＋ for
    /// more moods; on a later page (paced by `TipPacer`), at Get a Prompt. One per page.
    private func showTipsIfNew() async {
        guard !didShowMoodTip || !didShowPromptTip else { return }
        try? await Task.sleep(for: TipPacer.settle)
        guard !Task.isCancelled, extra == nil, TipPacer.mayShow() else { return }
        if !didShowMoodTip {
            didShowMoodTip = true
            TipPacer.shown()
            withAnimation(.easeOut(duration: 0.3)) { showsMoodTip = true }
        } else {
            await showPromptTipIfNew()
        }
    }

    private func closeMoodTip() {
        withAnimation(.easeOut(duration: 0.25)) { showsMoodTip = false }
        Haptics.tap()
        // After Show tips again, Get a Prompt's tip follows straight away.
        guard TipPacer.isReplaying else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            await showPromptTipIfNew()
        }
    }

    private func openMoodsFromTip() {
        closeMoodTip()
        openMoreMoods()
    }

    /// ＋ and "Tap to change": all thirty moods, for everyone to see. Without My Day Pro the 24
    /// beyond the page's six wear a crown there, and tapping one offers Pro.
    private func openMoreMoods() {
        extra = .moods
    }

    /// The Get a Prompt tip, once, when no other tip or sheet is open. It needs the button on
    /// screen with room round it for the cloud, so the page scrolls up first when it is low.
    private func showPromptTipIfNew() async {
        guard !didShowPromptTip, didShowMoodTip, !showsMoodTip, !showsPromptTip, extra == nil,
              promptFrame != .zero, pageBottom > 0
        else { return }
        if !promptTipFits {
            tipScrollTarget = "mood"
            try? await Task.sleep(for: .seconds(0.6))
            tipScrollTarget = nil
        }
        guard promptTipFits, !didShowPromptTip, !showsMoodTip, extra == nil else { return }
        didShowPromptTip = true
        TipPacer.shown()
        withAnimation(.easeOut(duration: 0.3)) { showsPromptTip = true }
    }

    /// Room above Get a Prompt for the kitten and below it for the cloud and the arrow.
    private var promptTipFits: Bool {
        promptFrame.midY - 125 >= 60 && promptFrame.midY + 80 <= pageBottom
    }

    private func closePromptTip() {
        withAnimation(.easeOut(duration: 0.25)) { showsPromptTip = false }
        Haptics.tap()
    }

    private func tryPromptFromTip() {
        closePromptTip()
        promptTapped()
    }

    /// The picture, then the cards on their panel.
    private func scroller(_ proxy: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                JournalHero(width: proxy.size.width, statusBar: statusBar(safeTop: proxy.safeAreaInsets.top))
                    .onGeometryChange(for: Bool.self) { geometry in
                        geometry.frame(in: .global).maxY > proxy.safeAreaInsets.top + 60
                    } action: { isVisible in
                        heroIsVisible = isVisible
                    }
                cards
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                    .background(alignment: .top) {
                        JournalPanel()
                    }
                    .padding(.top, -JournalScene.composer.overlap(width: proxy.size.width))
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .modifier(ComposerTopEdge(hidden: heroIsVisible))
        .ignoresSafeArea(edges: .top)
    }

    private func statusBar(safeTop: CGFloat) -> CGFloat {
        presentation == .sheet ? 0 : JournalScene.windowStatusBar(fallback: max(0, safeTop - 44))
    }

    private var cards: some View {
        VStack(spacing: 16) {
            dayRow
            moodCard
                .id("mood")
            DayListCard(kind: .activities, chosen: $upTo, onEdit: { editingList = .activities }, items: activityItems)
                .id("upto")
            DayListCard(kind: .goals, chosen: $goalsMet, onEdit: { editingList = .goals }, items: goalItems)
                .id("goals")
            writeCard
                .id("write")
            extrasCard
                .id("extras")
            reflectionCard(title: date.isToday ? "Today I'm grateful for…" : "I'm grateful for…",
                           art: "JournalJar", placeholder: "What are you grateful for?",
                           text: $gratitude)
            reflectionCard(title: "A highlight of my day…", art: "JournalHighlightStar",
                           placeholder: "What made today special?", text: $highlight)
            reflectionCard(title: "Tomorrow I look forward to…", art: "JournalSprout",
                           placeholder: "What are you excited about?", text: $lookingForward,
                           titleColor: JournalStyle.ink)
            littleWinCard
            saveButton
                .padding(.top, 6)
                .id("save")
        }
    }

    // MARK: Day and weather

    private var dayRow: some View {
        HStack(spacing: 10) {
            Button {
                extra = .date
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(JournalStyle.pinkGradient)
                    // The whole date when it fits, a shorter one when it doesn't.
                    ViewThatFits(in: .horizontal) {
                        dateText(.dateTime.weekday(.wide).day().month(.wide).year())
                        dateText(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
                        dateText(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(JournalStyle.pink)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 54)
                .background(Capsule().fill(Color.white.opacity(0.92)))
                .shadow(color: JournalStyle.pink.opacity(0.12), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PressScaleStyle(scale: 0.97))
            .accessibilityLabel("Day: \(date.formatted(date: .complete, time: .omitted))")
            .accessibilityHint("Pick another day")

            Spacer(minLength: 0)

            Button {
                extra = .weather
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: weather?.symbol ?? "sun.max.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 26))
                        .opacity(weather == nil ? 0.6 : 1)
                    Text(weatherChipText)
                        .font(.rounded(temperature.isEmpty ? .headline : .title3, weight: .heavy))
                        .foregroundStyle(weather == nil && temperature.isEmpty ? JournalStyle.soft : JournalStyle.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 54)
                .background(Capsule().fill(Color.white.opacity(0.92)))
                .shadow(color: JournalStyle.pink.opacity(0.12), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PressScaleStyle(scale: 0.97))
            .accessibilityLabel(weather.map { "Weather: \($0.label) \(temperature)" } ?? "Add the weather")
        }
    }

    private func dateText(_ format: Date.FormatStyle) -> some View {
        Text(date.formatted(format))
            .font(.rounded(.headline, weight: .heavy))
            .foregroundStyle(JournalStyle.ink)
            .lineLimit(1)
            .fixedSize()
    }

    private var voiceNoteStatus: String? {
        switch voiceNotes.count {
        case 0: nil
        case 1: "1 note"
        default: "\(voiceNotes.count) notes"
        }
    }

    private var weatherChipText: String {
        if !temperature.isEmpty { return temperature }
        return weather?.label ?? "Weather"
    }

    // MARK: Mood

    /// The six everyday moods, always shown; ＋ opens "Choose your mood" with all thirty.
    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                cardTitle(date.isToday ? "How are you feeling today?" : "How were you feeling?", color: JournalStyle.plum)
                Spacer(minLength: 4)
                Button(action: openMoreMoods) {
                    PlusBubble(diameter: 38)
                        .overlay(alignment: .topTrailing) {
                            if !pro.isActive {
                                ProCrown(size: 18)
                                    .offset(x: 6, y: -6)
                            }
                        }
                }
                .buttonStyle(PressScaleStyle())
                .anchorPreference(key: MoodPlusAnchorKey.self, value: .bounds) { $0 }
                .accessibilityLabel("More moods")
                .accessibilityHint("Choose from all the moods")
            }
            // All six in one row, small, so the page has room for the writing.
            HStack(spacing: 5) {
                ForEach(Mood.pickerMoods) { option in
                    moodButton(option)
                }
            }
            if moodPicked, !Mood.pickerMoods.contains(mood) {
                chosenMood
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .journalCard()
    }

    /// A mood picked with ＋ (one of the six shows as selected in the grid instead).
    private var chosenMood: some View {
        Button(action: openMoreMoods) {
            HStack(spacing: 12) {
                Image(mood.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Feeling \(mood.label)")
                        .font(.rounded(.title3, weight: .heavy))
                        .foregroundStyle(mood.chooserColors.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Tap to change")
                        .font(.rounded(.subheadline, weight: .semibold))
                        .foregroundStyle(JournalStyle.soft)
                }
                Spacer(minLength: 0)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, JournalStyle.selectedMoodEdge)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(JournalStyle.selectedMoodFill))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(JournalStyle.selectedMoodEdge, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle(scale: 0.98))
        .accessibilityLabel("Feeling \(mood.label)")
        .accessibilityHint("Choose another mood")
        .accessibilityAddTraits(.isSelected)
    }

    private func moodButton(_ option: Mood) -> some View {
        let isOn = option == mood
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                mood = option
                moodPicked = true
            }
            Haptics.tap()
            SoundEffects.play(.moodStar)
        } label: {
            VStack(spacing: 3) {
                Image(option.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .scaleEffect(isOn ? 1.08 : 1)
                Text(option.label)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(isOn ? JournalStyle.ink : JournalStyle.moodLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isOn ? JournalStyle.selectedMoodFill : Color.white.opacity(0.7)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isOn ? JournalStyle.selectedMoodEdge : Color.clear, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isOn ? AccessibilityTraits.isSelected : [])
    }

    // MARK: Writing

    private var writeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    cardTitle("Write about your day…", icon: "JournalWriteIcon", color: JournalStyle.plum, heart: false)
                    Spacer(minLength: 6)
                    promptButton
                }
                VStack(alignment: .leading, spacing: 10) {
                    cardTitle("Write about your day…", icon: "JournalWriteIcon", color: JournalStyle.plum, heart: false)
                    promptButton
                }
            }
            writingBox
            // What was added from the extras sits right under the writing.
            attachments
        }
        .journalCard()
    }

    /// One line naming the day. Left empty, the page is named after its mood, as the hint shows.
    private var headingField: some View {
        TextField("Heading", text: $title,
                  prompt: Text(moodPicked ? mood.dayName : "Name your day…")
                      .foregroundStyle(JournalStyle.placeholder))
            .font(.rounded(.title2, weight: .heavy))
            .foregroundStyle(JournalStyle.plum)
            .multilineTextAlignment(.center)
            .submitLabel(.next)
            .focused($headingFocused)
            .onSubmit { textFocused = true }
            .padding(.top, 6)
            .accessibilityHint("A word or two about your day, like A wonderful day")
    }

    private var promptButton: some View {
        Button(action: promptTapped) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Get a Prompt")
                if !pro.isActive {
                    ProCrown(size: 20)
                }
            }
            .font(.rounded(.headline, weight: .heavy))
            .foregroundStyle(JournalStyle.pink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Capsule().fill(JournalStyle.pinkFill))
        }
        .buttonStyle(PressScaleStyle())
        .anchorPreference(key: PromptButtonAnchorKey.self, value: .bounds) { $0 }
        .onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: .global)
        } action: { frame in
            promptFrame = frame
        }
    }

    /// Like a page: the heading, a line with a heart, then the writing.
    private var writingBox: some View {
        VStack(spacing: 12) {
            headingField
            HeartDivider(lineLength: nil, heartSize: 20)
                .padding(.horizontal, 4)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(isDictating ? "Listening… just say what's on your mind 💭"
                                     : "Share your thoughts, feelings, moments or anything on your mind…")
                        .font(.rounded(.body, weight: .medium))
                        .foregroundStyle(JournalStyle.placeholder)
                        .padding(.horizontal, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(JournalStyle.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 170)
                    .focused($textFocused)
            }
            writingFooter
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(JournalStyle.fieldFill))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(JournalStyle.pink.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }

    /// Two little hearts, the character count (out of 1,000 without My Day Pro, with a crown to
    /// unlock unlimited writing once the page is nearly full; with Pro, no limit: "1,234 / ∞"),
    /// and the yellow 🎙 to speak instead of typing. The
    /// 🎙 sits bottom right, where the thumb rests and where the keyboard's own dictation key is;
    /// what is said is added after what is already written. Journal pauses are longer, so it
    /// waits 4 seconds of quiet before it stops by itself.
    private var writingFooter: some View {
        HStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 2) {
                Image(systemName: "heart.fill").font(.system(size: 16))
                Image(systemName: "heart.fill").font(.system(size: 10))
            }
            .foregroundStyle(Color(hex: 0xFF8CC6))
            .accessibilityHidden(true)
            Spacer(minLength: 8)
            writingCount
            DictationButton(text: $text, diameter: 44, isListening: $isDictating, look: .yellow,
                            pauseAfterSpeech: .seconds(4)) {
                headingFocused = false
                textFocused = false
            }
        }
    }

    @ViewBuilder
    private var writingCount: some View {
        let words = JournalWords.count(text)
        if pro.isActive {
            Text("\(words.formatted()) words / ∞")
                .font(.rounded(.footnote, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(JournalStyle.soft)
                .accessibilityLabel("\(words) words, no limit")
        } else {
            let nearlyFull = words >= Self.wordLimit * 9 / 10
            Button {
                proOffer = .unlimitedWriting
            } label: {
                HStack(spacing: 5) {
                    if nearlyFull {
                        ProCrown(size: 16)
                    }
                    Text("\(words)/\(Self.wordLimit.formatted()) words")
                        .font(.rounded(.footnote, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(nearlyFull ? JournalStyle.pink : JournalStyle.soft)
                }
            }
            .buttonStyle(.plain)
            .disabled(!nearlyFull)
            .accessibilityLabel("\(words) of \(Self.wordLimit) words")
            .accessibilityHint(nearlyFull ? "Write without a limit with My Day Pro" : "")
        }
    }

    // MARK: Extras

    private var extrasCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle("Add some extras", icon: "JournalExtrasIcon", color: JournalStyle.ink)
            // All six in one row of small tiles.
            HStack(alignment: .top, spacing: 5) {
                photoTile
                extraTile("Sticker", art: "ExtraSticker",
                          status: stickers.isEmpty ? nil : "\(Sticker.list(from: stickers).count) added") {
                    extra = .sticker
                }
                extraTile("Voice", art: "ExtraVoice", status: voiceNoteStatus, locked: !pro.isActive) {
                    recordVoiceNote(continuing: nil)
                }
                extraTile("Location", art: "ExtraLocation", status: place.trimmed.isEmpty ? nil : place.trimmed) {
                    extra = .place
                }
                extraTile("Weather", art: "ExtraWeather", status: weather?.label) { extra = .weather }
                extraTile("Tags", art: "ExtraTag", status: tags.isEmpty ? nil : "\(tags.count) tags") {
                    extra = .tags
                }
            }
        }
        .journalCard()
    }

    /// Add Photo: the photo library, with My Day Pro (the photos already on the page stay).
    @ViewBuilder
    private var photoTile: some View {
        if pro.isActive {
            photoPicker
        } else {
            extraTile("Photo", art: "ExtraPhoto",
                      status: photos.isEmpty ? nil : "\(photos.count)/\(Self.maxPhotos)", locked: true) {
                proOffer = .journalPhotos
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $pickerItems, maxSelectionCount: max(1, Self.maxPhotos - photos.count),
                     matching: .images) {
            tileLabel("Photo", art: "ExtraPhoto",
                      status: photos.isEmpty ? nil : "\(photos.count)/\(Self.maxPhotos)")
                .overlay {
                    if isLoadingPhotos {
                        ProgressView()
                    }
                }
        }
        .buttonStyle(PressScaleStyle())
        .disabled(photos.count >= Self.maxPhotos || isLoadingPhotos)
    }

    private func extraTile(_ title: String, art: String, status: String?, locked: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            tileLabel(title, art: art, status: status)
                .overlay(alignment: .topTrailing) {
                    if locked {
                        ProCrown(size: 16)
                            .padding(2)
                    }
                }
        }
        .buttonStyle(PressScaleStyle())
        .accessibilityValue(locked ? "My Day Pro" : "")
    }

    private func tileLabel(_ title: String, art: String, status: String?) -> some View {
        VStack(spacing: 3) {
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(height: 26)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(JournalStyle.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let status {
                Text(status)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(JournalStyle.pink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 66)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(status == nil ? Color.white : JournalStyle.pink.opacity(0.5), lineWidth: 1.5))
        .shadow(color: JournalStyle.pink.opacity(0.1), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }

    /// What was added from the extras (photos, stickers, the voice note, the place and tags),
    /// shown under the writing.
    @ViewBuilder
    private var attachments: some View {
        if !photos.isEmpty {
            photoStrip
        }
        if !stickers.isEmpty {
            StickerRow(stickers: stickers, size: 44) { index in
                var list = Sticker.list(from: stickers)
                list.remove(at: index)
                stickers = Sticker.text(for: list)
            }
        }
        ForEach(Array(voiceNotes.enumerated()), id: \.element.id) { index, note in
            VoiceNotePlayer(data: note.audio, title: VoiceNoteDraft.title(index: index, count: voiceNotes.count),
                            duration: note.duration, recordedAt: note.recordedAt,
                            onContinue: {
                                recordVoiceNote(continuing: note.id)
                            },
                            continueLocked: !pro.isActive,
                            onDelete: {
                                withAnimation(.snappy) { voiceNotes.removeAll { $0.id == note.id } }
                            })
        }
        if !place.trimmed.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(JournalStyle.pink)
                Text(place.trimmed)
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(JournalStyle.ink)
                Spacer(minLength: 0)
                Button {
                    place = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(JournalStyle.soft.opacity(0.6))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Remove the place")
            }
            .padding(.leading, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(JournalStyle.fieldFill))
        }
        if !tags.isEmpty {
            TagChips(tags: tags) { tag in
                tags.removeAll { $0 == tag }
            }
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(photos) { photo in
                    Color.clear
                        .frame(width: 84, height: 84)
                        .overlay {
                            if let preview = photo.preview {
                                Image(uiImage: preview).resizable().scaledToFill()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    }

    // MARK: Reflections

    private func reflectionCard(title: String, art: String, placeholder: String, text: Binding<String>,
                                titleColor: Color = JournalStyle.plum) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 72)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(JournalStyle.pink)
                        .accessibilityHidden(true)
                    if !pro.isActive {
                        Spacer(minLength: 0)
                        ProCrown(size: 20)
                    }
                }
                reflectionField(placeholder, text: text)
            }
        }
        .journalCard()
    }

    /// A reflection to write in, or, for a free account, locked: what was written before still
    /// shows, with a little lock, and a tap offers My Day Pro.
    @ViewBuilder
    private func reflectionField(_ placeholder: String, text: Binding<String>) -> some View {
        if pro.isActive {
            reflectionTextField(placeholder, text: text)
        } else {
            lockedReflection(placeholder, text: text.wrappedValue)
        }
    }

    private func lockedReflection(_ placeholder: String, text: String) -> some View {
        Button {
            proOffer = .reflections
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Text(text.trimmed.isEmpty ? placeholder : text)
                    .font(.rounded(.body, weight: .medium))
                    .foregroundStyle(text.trimmed.isEmpty ? JournalStyle.placeholder : JournalStyle.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(JournalStyle.pink.opacity(0.75))
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(JournalStyle.fieldFill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(JournalStyle.pink.opacity(0.18), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue("Locked, My Day Pro")
        .accessibilityHint("Shows what My Day Pro unlocks")
    }

    private func reflectionTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text,
                  prompt: Text(placeholder).foregroundStyle(JournalStyle.placeholder),
                  axis: .vertical)
            .font(.rounded(.body, weight: .medium))
            .foregroundStyle(JournalStyle.ink)
            .lineLimit(1...5)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(JournalStyle.fieldFill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(JournalStyle.pink.opacity(0.18), lineWidth: 1))
    }

    /// Today's Little Win: one optional line, like "Finished my workout."
    private var littleWinCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("🏆")
                .font(.system(size: 34))
                .frame(width: 58, height: 58)
                .background(Circle().fill(Palette.cream))
                .overlay(Circle().strokeBorder(Palette.butter, lineWidth: 1.5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text(date.isToday ? "Today's Little Win" : "My Little Win")
                        .font(.rounded(.headline, weight: .heavy))
                        .foregroundStyle(Palette.cocoa)
                    if !pro.isActive {
                        Spacer(minLength: 0)
                        ProCrown(size: 20)
                    }
                }
                reflectionField("🌟 My little win \(date.isToday ? "today" : "that day")…", text: $littleWin)
            }
        }
        .journalCard()
    }

    // MARK: Save

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 12) {
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .bold))
                Image("JournalSaveIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 32)
                Text("Save Journal Entry")
                    .font(.rounded(.title3, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF7DBE), Color(hex: 0xF5238F)],
                                                      startPoint: .top, endPoint: .bottom)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.55), lineWidth: 1.5))
            .shadow(color: JournalStyle.pink.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressScaleStyle(scale: 0.97))
        .disabled(!canSave || isLoadingPhotos)
        .opacity(canSave ? 1 : 0.6)
    }

    // MARK: Menu and sheets

    private var moreMenu: some View {
        Menu {
            Button {
                isFavorite.toggle()
                entry?.isFavorite = isFavorite
                Haptics.tap()
            } label: {
                Label(isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: isFavorite ? "heart.slash" : "heart")
            }
            Button {
                startNewPage()
            } label: {
                Label("Start a New Page", systemImage: "square.and.pencil")
            }
        } label: {
            Image(uiImage: PriorityMoreSymbol.image)
                .foregroundStyle(JournalStyle.pink)
                .accessibilityLabel("More")
        }
    }

    @ViewBuilder
    private func extraSheet(_ extra: Extra) -> some View {
        switch extra {
        case .date: JournalDateSheet(date: $date)
        case .moods: MoodChooserSheet(mood: $mood, moodPicked: $moodPicked, isToday: date.isToday)
        case .sticker: StickerPickerSheet(stickers: $stickers)
        case .voice: VoiceNoteSheet(notes: $voiceNotes, continuing: voiceContinuing)
        case .place: PlaceSheet(place: $place)
        case .weather: WeatherSheet(weather: $weather, temperature: $temperature)
        case .tags: TagPickerSheet(tags: $tags)
        }
    }

    // MARK: Helpers

    private func cardTitle(_ title: String, icon: String? = nil, color: Color, heart: Bool = true) -> some View {
        HStack(spacing: 8) {
            if let icon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.rounded(.title3, weight: .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityAddTraits(.isHeader)
            if heart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(JournalStyle.pink)
                    .accessibilityHidden(true)
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeInOut(duration: 0.3)) {
                if toast == message { toast = nil }
            }
        }
    }

    // MARK: Actions

    /// Get a Prompt: a prompt, with My Day Pro.
    private func promptTapped() {
        if pro.isActive {
            addPrompt()
        } else {
            proOffer = .prompts
        }
    }

    /// Voice Note (and a note's Continue): recording, with My Day Pro. The notes already on the
    /// page play for everyone.
    private func recordVoiceNote(continuing note: VoiceNoteDraft.ID?) {
        guard pro.isActive else {
            proOffer = .voiceNotes
            return
        }
        voiceContinuing = note
        extra = .voice
    }

    private func addPrompt() {
        let unused = JournalPresets.prompts.filter { !text.contains($0) }
        let prompt = (unused.isEmpty ? JournalPresets.prompts : unused).randomElement() ?? JournalPresets.prompts[0]
        let separator = (text.isEmpty || text.hasSuffix("\n")) ? "" : "\n\n"
        text += separator + prompt + " "
        textFocused = true
        Haptics.tap()
    }

    private func startNewPage() {
        withAnimation(.snappy) {
            entry = nil
            date = .now
            title = ""
            text = ""
            mood = .happy
            moodPicked = false
            isFavorite = false
            littleWin = ""
            gratitude = ""
            highlight = ""
            lookingForward = ""
            stickers = ""
            tags = []
            upTo = []
            goalsMet = []
            place = ""
            weather = nil
            temperature = ""
            voiceNotes = []
            photos = []
        }
        showToast("A fresh page ✨")
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
        let isNewPage = entry == nil
        let page: JournalEntry
        if let entry {
            page = entry
        } else {
            page = JournalEntry(date: date)
            context.insert(page)
            entry = page
        }
        page.date = date
        page.title = title.trimmed
        page.body = text.trimmed
        page.mood = mood
        page.isFavorite = isFavorite
        page.littleWin = littleWin.trimmed
        page.gratitude = gratitude.trimmed
        page.highlight = highlight.trimmed
        page.lookingForward = lookingForward.trimmed
        page.stickers = stickers
        page.tags = tags
        // In the lists' order (anything no longer on them after).
        page.activities = activityItems.filter(upTo.contains) + upTo.subtracting(activityItems).sorted()
        page.goals = goalItems.filter(goalsMet.contains) + goalsMet.subtracting(goalItems).sorted()
        page.place = place.trimmed
        page.weather = weather
        page.temperature = temperature
        page.updatedAt = .now
        savePhotos(to: page)
        saveVoiceNotes(to: page)

        Haptics.success()
        headingFocused = false
        textFocused = false
        if presentation == .sheet {
            dismiss()
        } else if !router.replaceTop(with: AppRoute.savedJournalPage(page), in: hostTab) {
            showToast("Saved to your journal 💖")
        }
        if isNewPage {
            noteJournalMilestone(for: page)
        }
    }

    /// A new page that makes 5 pages, or a 3-day writing streak, is a happy moment: the rating
    /// card may come once "Saved" has shown.
    private func noteJournalMilestone(for page: JournalEntry) {
        let pages = (try? context.fetch(FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.deletedAt == nil }))) ?? []
        let dates = pages.filter { $0 !== page }.map(\.date) + [page.date]
        if RatingPrompt.isJournalMilestone(pageDates: dates) {
            rating.happyMoment()
        }
    }

    /// Removes voice notes that were deleted, keeps the rest in order (with anything recorded
    /// onto them) and adds new ones. A page's one older voice note becomes the first of them.
    private func saveVoiceNotes(to page: JournalEntry) {
        let kept = Set(voiceNotes.compactMap { $0.existing?.persistentModelID })
        for note in page.sortedVoiceNotes where !kept.contains(note.persistentModelID) {
            context.delete(note)
        }
        var saved: [VoiceNoteDraft] = []
        for (index, draft) in voiceNotes.enumerated() {
            if let existing = draft.existing {
                existing.order = index
                if draft.isChanged {
                    existing.audio = draft.audio
                    existing.duration = draft.duration
                    existing.updatedAt = .now
                }
                saved.append(VoiceNoteDraft(saved: existing))
            } else {
                let note = JournalVoiceNote(audio: draft.audio, duration: draft.duration, order: index,
                                            createdAt: draft.recordedAt)
                context.insert(note)
                note.entry = page
                saved.append(VoiceNoteDraft(saved: note))
            }
        }
        page.voiceNote = nil
        voiceNotes = saved
    }

    /// Removes photos that were taken out, keeps the rest in the new order and adds new ones.
    private func savePhotos(to page: JournalEntry) {
        let kept = Set(photos.compactMap { $0.existing?.persistentModelID })
        for photo in page.sortedPhotos where !kept.contains(photo.persistentModelID) {
            context.delete(photo)
        }
        var saved: [PhotoDraft] = []
        for (index, draft) in photos.enumerated() {
            if let existing = draft.existing {
                existing.order = index
                saved.append(draft)
            } else {
                let photo = JournalPhoto(imageData: draft.imageData, thumbnailData: draft.thumbnailData, order: index)
                context.insert(photo)
                photo.entry = page
                saved.append(PhotoDraft(existing: photo, imageData: draft.imageData,
                                        thumbnailData: draft.thumbnailData, preview: draft.preview))
            }
        }
        photos = saved
    }
}

/// Pick the day (and time) of a journal page.
struct JournalDateSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                DatePicker("Day", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(JournalStyle.pink)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))
                    .padding(20)
            }
            .background(Color(hex: 0xFFF3F8))
            .navigationTitle("Pick a Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

/// Counting the words of a journal page (runs of letters, digits or marks between spaces and
/// line breaks).
enum JournalWords {
    static func count(_ text: String) -> Int {
        var words = 0
        var inWord = false
        for character in text {
            if character.isWhitespace {
                inWord = false
            } else if !inWord {
                inWord = true
                words += 1
            }
        }
        return words
    }

    /// The text up to the end of its `words`th word.
    static func prefix(_ text: String, words limit: Int) -> String {
        var words = 0
        var inWord = false
        for index in text.indices {
            if text[index].isWhitespace {
                inWord = false
            } else if !inWord {
                inWord = true
                words += 1
                if words > limit {
                    return String(text[..<index])
                }
            }
        }
        return text
    }
}

/// No white haze at the top of the writing page (iOS 26's scroll edge effect): the picture stays
/// clear there.
private struct ComposerTopEdge: ViewModifier {
    let hidden: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(hidden, for: .top)
        } else {
            content
        }
    }
}
