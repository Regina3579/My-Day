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
    @AppStorage(Prefs.journalLock) private var journalLock = false
    @AppStorage(Prefs.journalLockMethod) private var lockMethodRaw = JournalLockMethod.biometrics.rawValue
    @AppStorage(Prefs.didShowICloudTip) private var didShowICloudTip = false
    /// Where Settings → iCloud is, and the part of the screen the list shows (between the
    /// navigation bar and the tab bar), for the first-time iCloud tip.
    @State private var iCloudTarget = ICloudTipTarget()
    @State private var visibleTop: CGFloat = 0
    @State private var visibleBottom: CGFloat = 0
    /// Turning the lock on or off, or changing how it opens.
    @State private var lockGoal: JournalLockSetupSheet.Goal?
    @State private var confirmClearDone = false
    @State private var confirmEraseAll = false

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
                    Button {
                        SoundEffects.play(.reminder)
                    } label: {
                        HStack {
                            Label {
                                Text("Reminder Sound")
                                    .foregroundStyle(Palette.ink)
                            } icon: {
                                Image(systemName: "music.note")
                            }
                            Spacer()
                            Text("Gentle Bloom")
                                .foregroundStyle(Palette.inkSoft)
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(Palette.hotPink)
                        }
                    }
                    .accessibilityLabel("Reminder Sound, Gentle Bloom")
                    .accessibilityHint("Plays the sound")
                } header: {
                    Text("Sounds & Haptics")
                } footer: {
                    Text("A soft “ting” when you tick off a to-do or a priority, a little chime when the day's last one is done, and a bubbly “pop… ting” when you pick a mood star in your journal. My Day's sounds stay quiet when your iPhone is on Silent and never stop your music. To-do reminders arrive with “Gentle Bloom”, a 3-second music-box melody: tap Reminder Sound to hear it.")
                }

                Section {
                    Toggle(isOn: lockToggle) {
                        Label("Lock My Journal", systemImage: "lock.fill")
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
                    Text(lockFooter)
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
                } footer: {
                    Text("See the first-time tips again, one at a time: on To-Dos (a new quote every day, Speak a Task, then Photo), the Reminder tip when you next open a to-do, the moods and Get a Prompt tips when you next write a journal page, and the iCloud tip when you next come to Settings.")
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
                // `settings-lock-choose` opens "Lock My Journal". Run when the route turns to
                // Settings, as this tab may start before the route is read.
                guard router.tab == .settings else { return }
                if DebugLaunchRoute.takeSettingsLockChoose() {
                    try? await Task.sleep(for: .seconds(1))
                    lockGoal = .turnOn
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
                let anchor: String? = DebugLaunchRoute.takeSettingsSounds() ? "sounds"
                    : DebugLaunchRoute.takeSettingsLock() ? "lock" : showsICloud ? "icloud"
                    : DebugLaunchRoute.takeSettingsTips() ? "tips"
                    : DebugLaunchRoute.takeSettingsRate() ? "rate" : nil
                guard let anchor else { return }
                try? await Task.sleep(for: .seconds(1))
                reader.scrollTo(anchor, anchor: .top)
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
            set: { lockGoal = $0 ? .turnOn : .turnOff }
        )
    }

    /// How the journal opens now (Face ID when a pattern or passcode is missing).
    private var lockMethod: JournalLockMethod {
        let chosen = JournalLockMethod(rawValue: lockMethodRaw) ?? .biometrics
        return chosen.usesSecret && !JournalSecretStore.hasSecret(for: chosen) ? .biometrics : chosen
    }

    private var lockFooter: String {
        guard journalLock else {
            return "Keep your journal private with Face ID, a pattern or a number passcode."
        }
        return "Your journal asks for \(lockMethod.askedFor) each time you come back to the app."
            + (lockMethod.usesSecret ? " Forgot it? You can open it with \(JournalLock.methodName) instead." : "")
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
        try? await Task.sleep(for: .seconds(0.8))
        guard !Task.isCancelled, canShowICloudTip else { return }
        if !ICloudTip.fits(iCloudTarget, in: visibleFrame) {
            withAnimation(.easeInOut(duration: 0.4)) {
                reader.scrollTo("icloud", anchor: UnitPoint(x: 0.5, y: 0.7))
            }
            try? await Task.sleep(for: .seconds(0.6))
        }
        guard !Task.isCancelled, canShowICloudTip, ICloudTip.fits(iCloudTarget, in: visibleFrame) else { return }
        didShowICloudTip = true
        withAnimation(.easeOut(duration: 0.3)) { router.iCloudTip = iCloudTarget }
    }

    /// Nothing else is open: no sheet, menu, question or rating card.
    private var canShowICloudTip: Bool {
        !didShowICloudTip && router.tab == .settings && router.iCloudTip == nil && router.sheet == nil
            && !router.isMenuOpen && lockGoal == nil && !confirmClearDone && !confirmEraseAll && !rating.isShowing
    }

    /// Marks the seven first-time tips as not seen and opens today's To-Dos, where the first three
    /// come one at a time (the Reminder tip waits for the next to-do opened, the moods and Get a
    /// Prompt tips for the next journal page, the iCloud tip for the next visit here). My Day
    /// goes back to its home screen first, so To-Dos opens afresh even when it was already open there.
    private func showTipsAgain() {
        for key in [Prefs.didShowQuoteTip, Prefs.didShowVoiceTip, Prefs.didShowPhotoTip, Prefs.didShowMoodTip,
                    Prefs.didShowPromptTip, Prefs.didShowReminderTip, Prefs.didShowICloudTip] {
            UserDefaults.standard.set(false, forKey: key)
        }
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
