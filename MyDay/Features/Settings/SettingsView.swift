import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(DataStore.self) private var store
    @AppStorage(Prefs.userName) private var userName = ""
    @AppStorage(Prefs.carryOver) private var carryOver = true
    /// The Completed list on the To-Dos screen is open (it starts closed).
    @AppStorage(Prefs.showCompleted) private var showCompleted = false
    @AppStorage(Prefs.haptics) private var haptics = true
    @AppStorage(Prefs.taskCompletionSound) private var completionSound = true
    @AppStorage(Prefs.moodStarSound) private var moodStarSound = true
    @AppStorage(Prefs.journalLock) private var journalLock = false
    @AppStorage(Prefs.journalLockMethod) private var lockMethodRaw = JournalLockMethod.biometrics.rawValue
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

                ICloudSettingsSection()

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
                } header: {
                    Text("Sounds & Haptics")
                } footer: {
                    Text("A soft “ting” when you tick off a to-do or a priority, a little chime when the day's last one is done, and a bubbly “pop… ting” when you pick a mood star in your journal. My Day's sounds stay quiet when your iPhone is on Silent and never stop your music.")
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
                    LabeledContent("Version", value: version)
                    LabeledContent("Made with", value: "💖 for beautiful days")
                }
            }
            #if DEBUG
            .task(id: router.tab) {
                // `settings-sounds`, `settings-lock` and `settings-icloud`: show Sounds & Haptics,
                // the journal lock or iCloud for the screenshot; `settings-lock-choose` opens
                // "Lock My Journal". Run when the route turns to Settings, as this tab may start
                // before the route is read.
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
                let anchor: String? = DebugLaunchRoute.takeSettingsSounds() ? "sounds"
                    : DebugLaunchRoute.takeSettingsLock() ? "lock" : showsICloud ? "icloud" : nil
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
