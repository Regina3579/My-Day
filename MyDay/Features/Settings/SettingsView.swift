import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(DataStore.self) private var store
    @Environment(RatingPrompt.self) private var rating
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @AppStorage(Prefs.userName) private var userName = ""
    @AppStorage(Prefs.carryOver) private var carryOver = true
    /// The Completed list on the To-Dos screen is open (it starts closed).
    @AppStorage(Prefs.showCompleted) private var showCompleted = false
    @AppStorage(Prefs.haptics) private var haptics = true
    @AppStorage(Prefs.taskCompletionSound) private var completionSound = true
    @AppStorage(Prefs.moodStarSound) private var moodStarSound = true
    @AppStorage(Prefs.reminderSound) private var reminderSound: ReminderSound = .gentleBloom
    @AppStorage(Prefs.journalTheme) private var journalTheme: JournalTheme = .blushBlossom
    @Environment(MyDayPro.self) private var pro
    @AppStorage(Prefs.journalLock) private var journalLock = false
    @AppStorage(Prefs.showSteps) private var showSteps = true
    @AppStorage(Prefs.journalLockMethod) private var lockMethodRaw = JournalLockMethod.biometrics.rawValue
    @AppStorage(Prefs.didShowICloudTip) private var didShowICloudTip = false
    /// Where Settings → iCloud is, and the part of the screen the list shows (between the
    /// navigation bar and the tab bar), for the first-time iCloud tip.
    @State private var iCloudTarget = ICloudTipTarget()
    @State private var visibleTop: CGFloat = 0
    @State private var visibleBottom: CGFloat = 0
    /// Turning the lock on or off, or changing how it opens.
    @State private var lockGoal: JournalLockSetupSheet.Goal?
    /// Lock My Journal, tapped by a free account: the My Day Pro pop-up.
    @State private var proOffer: ProFeature?
    @State private var confirmClearDone = false
    @State private var confirmEraseAll = false
    #if DEBUG
    /// `settings-reminder-sound`: Reminder Sound opened for the screenshot.
    @State private var opensReminderSound = false
    /// `settings-journal-theme` and `pro-themes`: Journal Theme opened for the screenshot.
    @State private var opensJournalTheme = false
    #endif

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollViewReader { reader in
            Form {
                Section {
                    VStack(spacing: 10) {
                        HeroBanner(height: 150)
                        Text("My Day")
                            .font(.rounded(.title, weight: .heavy))
                            .foregroundStyle(Palette.ink)
                        Text("To-Do & Journal 💖")
                            .font(.rounded(.subheadline, weight: .semibold))
                            .foregroundStyle(Palette.hotPink)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)

                ProSettingsSection()

                Section("About you") {
                    TextField("Your name", text: $userName)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                }

                ICloudSettingsSection(tipTarget: $iCloudTarget)

                Section("Reminders") {
                    NavigationLink {
                        RemindersView()
                    } label: {
                        Label("Daily reminders", systemImage: "bell.badge.fill")
                    }
                }

                Section("To-Dos") {
                    Toggle(isOn: $carryOver) {
                        Label("Move unfinished items to today", systemImage: "arrow.uturn.forward.circle.fill")
                    }
                    Toggle(isOn: $showCompleted) {
                        Label("Show finished to-dos", systemImage: "checkmark.circle.fill")
                    }
                }

                Section {
                    Toggle(isOn: $completionSound) {
                        Label("Task Completion Sound", systemImage: "bell.and.waves.left.and.right.fill")
                    }
                    .id("sounds")
                    Toggle(isOn: $moodStarSound) {
                        Label("Mood Star Sound", systemImage: "sparkles")
                    }
                    Toggle(isOn: $haptics) {
                        Label("Gentle haptics", systemImage: "hand.tap.fill")
                    }
                    NavigationLink {
                        ReminderSoundView()
                    } label: {
                        HStack {
                            Label("Reminder Sound", systemImage: "music.note")
                                .layoutPriority(1)
                            Spacer()
                            Text(reminderSound.applying(pro: pro.isActive).title)
                                .foregroundStyle(Palette.inkSoft)
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("Sounds & Haptics")
                }

                Section {
                    NavigationLink {
                        JournalThemeView()
                    } label: {
                        HStack {
                            Label("Journal Theme", systemImage: "paintpalette.fill")
                                .layoutPriority(1)
                            Spacer()
                            Text(journalTheme.applying(pro: pro.isActive).title)
                                .foregroundStyle(Palette.inkSoft)
                                .lineLimit(1)
                        }
                    }
                    if StepCounter.shared.isAvailable {
                        Toggle(isOn: $showSteps) {
                            Label("Show my steps", systemImage: "figure.walk")
                        }
                        .onChange(of: showSteps) { _, isOn in
                            if isOn { Task { await StepCounter.shared.requestAccess() } }
                        }
                    }
                    Toggle(isOn: lockToggle) {
                        HStack(spacing: 6) {
                            Label("Lock My Journal", systemImage: "lock.fill")
                            if !pro.isActive && !journalLock {
                                ProCrown(size: 20)
                            }
                        }
                    }
                    .id("lock")
                    if journalLock {
                        ForEach(JournalLockMethod.allCases) { method in
                            Button {
                                if method != lockMethod { lockGoal = .switchTo(method) }
                            } label: {
                                JournalLockMethodRow(method: method, isOn: method == lockMethod,
                                                     isAvailable: method.usesSecret || JournalLock.canAuthenticate)
                            }
                            .disabled(!method.usesSecret && !JournalLock.canAuthenticate)
                        }
                        if lockMethod.usesSecret {
                            Button {
                                lockGoal = .changeSecret
                            } label: {
                                Label(lockMethod == .pattern ? "Change Pattern" : "Change Passcode",
                                      systemImage: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(Palette.hotPink)
                            }
                        }
                    }
                } header: {
                    Text("Journal")
                } footer: {
                    if let lockFooter {
                        Text(lockFooter)
                    }
                }

                Section {
                    Button(action: showTipsAgain) {
                        Label("Show tips again", systemImage: "lightbulb.fill")
                            .foregroundStyle(Palette.hotPink)
                    }
                    .id("tips")
                    #if DEBUG
                    // Builds run from Xcode only: the card otherwise waits for 7 days of use.
                    Button {
                        rating.preview()
                    } label: {
                        Label("Preview the rating card", systemImage: "star.bubble")
                            .foregroundStyle(Palette.hotPink)
                    }
                    #endif
                } header: {
                    Text("Tips")
                }

                Section("Your data") {
                    Button {
                        confirmClearDone = true
                    } label: {
                        Label("Clear finished items", systemImage: "checkmark.circle.badge.xmark")
                    }
                    Button(role: .destructive) {
                        confirmEraseAll = true
                    } label: {
                        Label("Erase everything", systemImage: "trash")
                            .foregroundStyle(Color.red)
                    }
                }

                Section {
                    Button(action: rateMyDay) {
                        Label("Rate My Day ⭐️", systemImage: "star.bubble.fill")
                            .foregroundStyle(Palette.hotPink)
                    }
                    .id("rate")
                    LabeledContent("Version", value: version)
                    LabeledContent("Made with", value: "💖 for beautiful days")
                }
            }
            // Where the list shows (below the navigation bar, above the tab bar), read from two
            // empty markers at its edges: the list's own geometry does not say.
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear
                    .frame(height: 0)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { visibleTop = $0 }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: 0)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { visibleBottom = $0 }
            }
            .task(id: router.tab) {
                await showICloudTipIfNew(scrollingWith: reader)
            }
            #if DEBUG
            .task(id: router.tab) {
                // `settings-sounds`, `settings-lock`, `settings-icloud`, `settings-tips` and
                // `settings-rate`: show Sounds & Haptics, the journal lock, iCloud, Tips or Rate
                // My Day for the screenshot;
                // `settings-lock-choose` opens "Lock My Journal" and `settings-reminder-sound`
                // opens Reminder Sound. Run when the route turns to Settings, as this tab may
                // start before the route is read.
                guard router.tab == .settings else { return }
                if DebugLaunchRoute.takeSettingsLockChoose() {
                    try? await Task.sleep(for: .seconds(1))
                    lockGoal = .turnOn
                }
                if DebugLaunchRoute.takeSettingsReminderSound() {
                    try? await Task.sleep(for: .seconds(1))
                    opensReminderSound = true
                }
                if DebugLaunchRoute.takeSettingsJournalTheme() {
                    try? await Task.sleep(for: .seconds(1))
                    opensJournalTheme = true
                }
                let showsICloud = DebugLaunchRoute.takeSettingsICloud()
                if showsICloud {
                    // The simulator has no iCloud account: a demo of the status after a sync.
                    store.syncStatus.showForScreenshot(.upToDate(Date().addingTimeInterval(-120)))
                }
                if DebugLaunchRoute.takeSettingsICloudTip() {
                    // `settings-icloud-tip`: as in its design, the status says it has just synced.
                    store.syncStatus.showForScreenshot(.upToDate(Date()))
                }
                let anchor: String? = DebugLaunchRoute.takeSettingsPro() ? "pro"
                    : DebugLaunchRoute.takeSettingsSounds() ? "sounds"
                    : DebugLaunchRoute.takeSettingsLock() ? "lock" : showsICloud ? "icloud"
                    : DebugLaunchRoute.takeSettingsTips() ? "tips"
                    : DebugLaunchRoute.takeSettingsRate() ? "rate" : nil
                guard let anchor else { return }
                try? await Task.sleep(for: .seconds(1))
                reader.scrollTo(anchor, anchor: .top)
            }
            .navigationDestination(isPresented: $opensReminderSound) {
                ReminderSoundView()
            }
            .navigationDestination(isPresented: $opensJournalTheme) {
                JournalThemeView()
            }
            #endif
        }
        .font(.rounded(.body))
        .scrollContentBackground(.hidden)
        .tabBarSafeArea()
        .background(DreamyBackground(theme: .garden))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: completionSound) { _, isOn in
            // A preview, so you know what it sounds like.
            if isOn { SoundEffects.play(.ting) }
        }
        .onChange(of: moodStarSound) { _, isOn in
            if isOn { SoundEffects.play(.moodStar) }
        }
        .sheet(item: $lockGoal) { goal in
            JournalLockSetupSheet(goal: goal)
        }
        .proOffer($proOffer)
        .confirmationDialog("Clear finished to-dos and priorities?", isPresented: $confirmClearDone, titleVisibility: .visible) {
            Button("Clear finished items", role: .destructive, action: clearFinished)
        }
        .confirmationDialog("Erase all to-dos, priorities and journal pages?", isPresented: $confirmEraseAll,
                            titleVisibility: .visible) {
            Button("Erase everything", role: .destructive, action: eraseAll)
        } message: {
            Text(store.syncsWithICloud
                 ? "They are erased from iCloud and your other devices too. This can't be undone."
                 : "This can't be undone.")
        }
    }

    // MARK: Journal lock

    /// The switch opens the sheet; the lock changes only once the sheet is done.
    private var lockToggle: Binding<Bool> {
        Binding(
            get: { journalLock },
            // Turning it on comes with My Day Pro. Turning it off never does: a lock set while
            // Pro was on stays until the person turns it off, so the journal never opens up by
            // itself.
            set: { isOn in
                if isOn && !pro.isActive {
                    proOffer = .journalLock
                } else {
                    lockGoal = isOn ? .turnOn : .turnOff
                }
            }
        )
    }

    /// How the journal opens now (Face ID when a pattern or passcode is missing).
    private var lockMethod: JournalLockMethod {
        let chosen = JournalLockMethod(rawValue: lockMethodRaw) ?? .biometrics
        return chosen.usesSecret && !JournalSecretStore.hasSecret(for: chosen) ? .biometrics : chosen
    }

    /// The one thing worth saying under Journal: a forgotten pattern or passcode isn't the end.
    private var lockFooter: String? {
        guard journalLock, lockMethod.usesSecret else { return nil }
        return "Forgot it? Open your journal with \(JournalLock.methodName)."
    }

    // MARK: Tips

    /// The part of the screen the list shows.
    private var visibleFrame: CGRect {
        CGRect(x: 0, y: visibleTop, width: 1, height: max(0, visibleBottom - visibleTop))
    }

    /// The first time Settings opens: after a moment, a tip points at Sync with iCloud. The list
    /// scrolls first when the iCloud card and the tip's card above it don't both fit on screen;
    /// it waits for another visit when something else is open.
    private func showICloudTipIfNew(scrollingWith reader: ScrollViewProxy) async {
        guard router.tab == .settings, !didShowICloudTip else { return }
        try? await Task.sleep(for: TipPacer.settle)
        guard !Task.isCancelled, canShowICloudTip, TipPacer.mayShow() else { return }
        if !ICloudTip.fits(iCloudTarget, in: visibleFrame) {
            withAnimation(.easeInOut(duration: 0.4)) {
                reader.scrollTo("icloud", anchor: UnitPoint(x: 0.5, y: 0.7))
            }
            try? await Task.sleep(for: .seconds(0.6))
        }
        guard !Task.isCancelled, canShowICloudTip, ICloudTip.fits(iCloudTarget, in: visibleFrame) else { return }
        didShowICloudTip = true
        TipPacer.shown()
        withAnimation(.easeOut(duration: 0.3)) { router.iCloudTip = iCloudTarget }
    }

    /// Nothing else is open: no sheet, menu, question or rating card.
    private var canShowICloudTip: Bool {
        !didShowICloudTip && router.tab == .settings && router.iCloudTip == nil && router.sheet == nil
            && !router.isMenuOpen && lockGoal == nil && !confirmClearDone && !confirmEraseAll && !rating.isShowing
    }

    /// Marks the ten first-time tips as not seen and opens today's To-Dos, where its three come
    /// one right after another (asked for, so no waiting: see `TipPacer`); the others come the
    /// next time their screen opens. My Day goes back to its home screen first, so To-Dos opens
    /// afresh even when it was already open there.
    private func showTipsAgain() {
        TipPacer.replayAll()
        Haptics.tap()
        router.goHome()
        let today = appState.today
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            router.open(.todos(today))
        }
    }

    // MARK: Rating

    /// Opens Apple's page to rate My Day, whenever someone wants to. The "Enjoying My Day?"
    /// card won't ask again after this.
    private func rateMyDay() {
        Haptics.tap()
        rating.rated()
        AppReview.open(openURL: openURL, requestReview: requestReview)
    }

    // MARK: Data

    private func clearFinished() {
        router.homePath = NavigationPath()
        router.calendarPath = NavigationPath()
        let finished = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.isCompleted == true }))) ?? []
        for task in finished {
            TaskActions.delete(task, in: context)
        }
        let finishedPriorities = (try? context.fetch(
            FetchDescriptor<Priority>(predicate: #Predicate { $0.isCompleted == true }))) ?? []
        for priority in finishedPriorities {
            context.delete(priority)
        }
        Haptics.success()
    }

    private func eraseAll() {
        // Leave any open page first, so nothing on screen shows a deleted item.
        router.homePath = NavigationPath()
        router.calendarPath = NavigationPath()

        let allTasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        for task in allTasks {
            TaskActions.delete(task, in: context)
        }
        let allPriorities = (try? context.fetch(FetchDescriptor<Priority>())) ?? []
        for priority in allPriorities {
            context.delete(priority)
        }
        let allEntries = (try? context.fetch(FetchDescriptor<JournalEntry>())) ?? []
        for entry in allEntries {
            context.delete(entry)
        }
        try? context.save()
        Haptics.success()
    }
}
